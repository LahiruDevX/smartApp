import 'package:flutter/material.dart';

import '../../features/meetings/meeting_service.dart';
import 'meeting_room_view_stub.dart'
    if (dart.library.html) 'meeting_room_view_web.dart'
    if (dart.library.io) 'meeting_room_view_mobile.dart' as impl;

/// The actual video call — a Jitsi Meet room. A native WebView on
/// Android/iOS, an iframe on web; desktop (no webview_flutter support there)
/// shows a short notice instead of crashing — same conditional-import
/// pattern as teacher3d_view.dart (see meeting_room_view_mobile.dart /
/// meeting_room_view_web.dart / meeting_room_view_stub.dart).
class MeetingRoomScreen extends StatelessWidget {
  const MeetingRoomScreen({super.key, required this.meeting});
  final Meeting meeting;

  @override
  Widget build(BuildContext context) => impl.buildMeetingRoomView(meeting);
}
