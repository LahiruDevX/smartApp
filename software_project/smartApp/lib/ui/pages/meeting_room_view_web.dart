import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import '../../features/meetings/meeting_service.dart';
import '../theme/chalk_theme.dart';

/// Picked by the `dart.library.html` branch of the conditional import — i.e.
/// Flutter web. Camera/mic access inside the iframe needs a secure context
/// (https, or http on localhost specifically) — see meeting_room_screen.dart.
Widget buildMeetingRoomView(Meeting meeting) => _MeetingRoomWeb(meeting: meeting);

int _seq = 0;

class _MeetingRoomWeb extends StatefulWidget {
  const _MeetingRoomWeb({required this.meeting});
  final Meeting meeting;

  @override
  State<_MeetingRoomWeb> createState() => _MeetingRoomWebState();
}

class _MeetingRoomWebState extends State<_MeetingRoomWeb> {
  late final String _viewType;
  String? _presenceViewType;
  html.EventListener? _presenceListener;

  bool get _isStudent => authService.user.value?.role == 'student';

  @override
  void initState() {
    super.initState();
    // Includes the room name as well as a per-instance counter: unique per
    // meeting AND safe if this widget is ever rebuilt into a fresh instance
    // for the same meeting (registerViewFactory only accepts a type once).
    _viewType = 'meeting-iframe-${widget.meeting.jitsiRoomName}-${_seq++}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      return html.IFrameElement()
        ..src = _meetingUrl()
        ..allow = 'camera; microphone; fullscreen; display-capture'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });

    if (_isStudent) {
      // join() is independent of the presence camera below — it must still
      // happen even if that camera/model fails, same as mobile's fire-and-forget
      // join() isn't gated on ML Kit being available.
      meetingService.join(widget.meeting.id).catchError((_) {});
      _startPresenceCheck();
    }
  }

  // Same room + display-name + config params as meeting_room_view_mobile.dart's
  // _meetingUrl(), so web joins the exact same Jitsi call.
  String _meetingUrl() {
    final name = authService.user.value?.email.split('@').first ?? 'Guest';
    final display = Uri.encodeComponent('"$name"');
    return 'https://meet.jit.si/${widget.meeting.jitsiRoomName}'
        '#userInfo.displayName=$display'
        '&config.prejoinPageEnabled=false';
  }

  // The Jitsi iframe above is a different origin (meet.jit.si), so its own
  // camera feed can't be read from this page. Instead, a second hidden
  // iframe opens its own getUserMedia stream purely for presence-checking —
  // same face-api.js (TinyFaceDetector) already vendored for the Attendance
  // feature, served at backend/public/meeting-presence (see
  // meeting_room_view_mobile.dart's ML Kit equivalent, _onFrameReceived).
  // Expect a second camera permission prompt in the browser; that's expected.
  void _startPresenceCheck() {
    _presenceViewType = 'meeting-presence-${widget.meeting.jitsiRoomName}-${_seq++}';

    ui_web.platformViewRegistry.registerViewFactory(_presenceViewType!, (int _) {
      return html.IFrameElement()
        ..src = '$apiBaseUrl/meeting-presence/index.html'
        ..allow = 'camera'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });

    _presenceListener = (html.Event event) {
      final data = (event as html.MessageEvent).data;
      if (data is! Map || data['source'] != 'meeting-presence') return;
      final type = data['type'];
      if (type == 'presence') {
        meetingService
            .presenceCheck(widget.meeting.id,
                faceDetected: data['faceDetected'] == true)
            .catchError((_) {});
      } else if (type == 'error') {
        // Model load failed, or this second camera prompt was denied — log
        // and move on. Must never affect the actual Jitsi video call.
        debugPrint('Meeting presence check unavailable: ${data['message']}');
      }
    };
    html.window.addEventListener('message', _presenceListener);
  }

  @override
  void dispose() {
    if (_presenceListener != null) {
      html.window.removeEventListener('message', _presenceListener);
    }
    if (_isStudent) {
      meetingService.leave(widget.meeting.id).catchError((_) => null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChalkColors.chalkboard,
      appBar: AppBar(
        backgroundColor: ChalkColors.chalkboard,
        foregroundColor: Colors.white,
        title: Text(widget.meeting.title,
            style: ChalkText.heading(size: 16, color: Colors.white)),
      ),
      body: Stack(
        children: [
          HtmlElementView(viewType: _viewType),
          if (_presenceViewType != null)
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: HtmlElementView(viewType: _presenceViewType!),
            ),
        ],
      ),
    );
  }
}
