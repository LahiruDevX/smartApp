import 'package:flutter/material.dart';

import '../../features/meetings/meeting_service.dart';
import 'meeting_room_view_stub.dart'
    if (dart.library.io) 'meeting_room_view_mobile.dart' as impl;

/// The actual video call — a Jitsi Meet room loaded in a WebView. Only
/// Android/iOS actually support webview_flutter; every other platform
/// (desktop, web) shows a short notice instead of crashing — same
/// conditional-import pattern as teacher3d_view.dart (see
/// meeting_room_view_mobile.dart / meeting_room_view_stub.dart).
class MeetingRoomScreen extends StatelessWidget {
  const MeetingRoomScreen({super.key, required this.meeting});
  final Meeting meeting;

  @override
  Widget build(BuildContext context) => impl.buildMeetingRoomView(meeting);
}
