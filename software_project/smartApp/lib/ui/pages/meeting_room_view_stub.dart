import 'package:flutter/material.dart';

import '../../features/meetings/meeting_service.dart';

/// Picked when neither `dart.library.html` nor `dart.library.io` matches
/// (in practice unreachable for a real Flutter build target — kept only to
/// satisfy the conditional import's required default, same as
/// teacher3d_view_stub.dart).
Widget buildMeetingRoomView(Meeting meeting) =>
    _MeetingRoomUnsupported(meeting: meeting);

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
