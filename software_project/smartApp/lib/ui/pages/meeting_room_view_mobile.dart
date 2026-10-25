import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../core/di/app_di.dart';
import '../../features/meetings/meeting_service.dart';
import '../theme/chalk_theme.dart';

const _facePresenceChannel = 'FacePresenceChannel';

// How often the student's camera is sampled for a presence check. Kept
// within the 60-90s window — frequent enough to catch someone stepping away,
// loose enough not to be intrusive or heavy on the device.
const _presenceCheckIntervalMs = 75000;

// Runs inside the Jitsi page. Finds the local camera preview, draws one
// frame to an off-screen canvas, and posts the JPEG (base64, no header) to
// Flutter. Never touches the network itself — Flutter decides what to do
// with the frame and nothing but the detector's boolean result leaves the
// device. `#localVideo_container video` is Jitsi Meet's long-standing DOM id
// for the local participant's own video thumbnail; the fallbacks cover
// older/newer markup without ever throwing if nothing is found.
const _presenceCheckScript = '''
(function() {
  if (window.__presenceCheckStarted) return;
  window.__presenceCheckStarted = true;
  var canvas = document.createElement('canvas');
  var ctx = canvas.getContext('2d');
  function findLocalVideo() {
    var el = document.querySelector('#localVideo_container video');
    if (el) return el;
    el = document.querySelector('video[id^="localVideo"]');
    if (el) return el;
    return document.querySelector('video');
  }
  function check() {
    try {
      var video = findLocalVideo();
      if (!video || !video.videoWidth || !video.videoHeight) return;
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      var dataUrl = canvas.toDataURL('image/jpeg', 0.5);
      var base64 = dataUrl.split(',')[1];
      if (base64) { $_facePresenceChannel.postMessage(base64); }
    } catch (e) {}
  }
  setInterval(check, $_presenceCheckIntervalMs);
})();
''';

/// Picked by the `dart.library.io` branch of the conditional import — i.e.
/// every non-web platform (mobile AND desktop). Mobile gets the real Jitsi
/// WebView; desktop (no webview_flutter support here) falls back to the
/// same short notice meeting_room_view_stub.dart shows.
Widget buildMeetingRoomView(Meeting meeting) {
  if (Platform.isAndroid || Platform.isIOS) {
    return _MeetingRoomScreen(meeting: meeting);
  }
  return _MeetingRoomUnsupported(meeting: meeting);
}

class _MeetingRoomUnsupported extends StatelessWidget {
  const _MeetingRoomUnsupported({required this.meeting});
  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(meeting.title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Video meetings run on the mobile app only.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// The real video call — a Jitsi Meet room loaded in a WebView. Opened for a
/// student's "Join" or a teacher's "Open Call". Only the student side tracks
/// attendance: join() on open, a periodic on-device face check sent as
/// presence-check(), and leave() on the way out. Teachers aren't tracked on
/// their own meeting.
class _MeetingRoomScreen extends StatefulWidget {
  const _MeetingRoomScreen({required this.meeting});
  final Meeting meeting;

  @override
  State<_MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<_MeetingRoomScreen> {
  late final WebViewController _webController;
  FaceDetector? _faceDetector;
  bool _leaving = false;

  bool get _isStudent => authService.user.value?.role == 'student';

  @override
  void initState() {
    super.initState();

    if (_isStudent) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
      );
      meetingService.join(widget.meeting.id).catchError((_) {});
    }

    unawaited(_requestMediaPermissions());

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        _facePresenceChannel,
        onMessageReceived: _onFrameReceived,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (_isStudent) {
              _webController.runJavaScript(_presenceCheckScript);
            }
          },
        ),
      );

    final androidController = _webController.platform;
    if (androidController is AndroidWebViewController) {
      androidController.setOnPlatformPermissionRequest((request) {
        request.grant();
      });
    }

    _webController.loadRequest(Uri.parse(_meetingUrl()));
  }

  Future<void> _requestMediaPermissions() async {
    try {
      await [Permission.camera, Permission.microphone].request();
    } catch (_) {
      // No permission_handler implementation on this platform, or the user
      // will be prompted by the WebView itself — either way, don't block.
    }
  }

  String _meetingUrl() {
    final name = authService.user.value?.email.split('@').first ?? 'Guest';
    final display = Uri.encodeComponent('"$name"');
    return 'https://meet.jit.si/${widget.meeting.jitsiRoomName}'
        '#userInfo.displayName=$display'
        '&config.prejoinPageEnabled=false';
  }

  Future<void> _onFrameReceived(JavaScriptMessage message) async {
    final detector = _faceDetector;
    if (detector == null) return; // teacher — no tracking on self

    File? tempFile;
    try {
      final bytes = base64Decode(message.message);
      final dir = await getTemporaryDirectory();
      tempFile = File(
          '${dir.path}/presence_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);

      final faces =
          await detector.processImage(InputImage.fromFilePath(tempFile.path));
      await meetingService.presenceCheck(widget.meeting.id,
          faceDetected: faces.isNotEmpty);
    } catch (_) {
      // Bad frame, detector hiccup, or the request failed — skip this round.
      // A run of misses naturally drags the presence ratio toward "absent",
      // which is the correct outcome, not an error to surface.
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<void> _handlePop() async {
    if (_leaving) return;
    _leaving = true;
    if (_isStudent) {
      try {
        await meetingService.leave(widget.meeting.id);
      } catch (_) {
        // Still leave the screen even if the network call failed.
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePop();
      },
      child: Scaffold(
        backgroundColor: ChalkColors.chalkboard,
        appBar: AppBar(
          backgroundColor: ChalkColors.chalkboard,
          foregroundColor: Colors.white,
          // No custom `leading` — the standard Flutter back arrow (routed
          // through PopScope above, so it still leaves() before popping)
          // beats a bespoke icon here: it's the one control guaranteed to
          // always be there and always mean "go back".
          title: Text(widget.meeting.title,
              style: ChalkText.heading(size: 16, color: Colors.white)),
        ),
        body: WebViewWidget(controller: _webController),
      ),
    );
  }
}
