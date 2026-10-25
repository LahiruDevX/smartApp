import '../../core/network/api_client.dart';

class Meeting {
  const Meeting({
    required this.id,
    required this.subjectId,
    this.subjectName,
    this.teacherId,
    required this.title,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.jitsiRoomName,
    required this.status,
    this.createdAt,
  });

  final int id;
  final int subjectId;
  final String? subjectName;
  final int? teacherId;
  final String title;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String jitsiRoomName;

  /// 'scheduled' | 'live' | 'ended'
  final String status;
  final DateTime? createdAt;

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));

  /// Joinable from 10 minutes before the scheduled start until it ends.
  bool get isJoinable {
    if (status == 'ended') return false;
    final now = DateTime.now();
    return now.isAfter(scheduledAt.subtract(const Duration(minutes: 10))) &&
        now.isBefore(endsAt);
  }

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        id: (j['id'] as num).toInt(),
        subjectId: (j['subjectId'] as num).toInt(),
        subjectName: j['subjectName'] as String?,
        teacherId: (j['teacherId'] as num?)?.toInt(),
        title: j['title'] as String,
        scheduledAt:
            DateTime.tryParse(j['scheduledAt'] as String) ?? DateTime.now(),
        durationMinutes: (j['durationMinutes'] as num).toInt(),
        jitsiRoomName: j['jitsiRoomName'] as String,
        status: j['status'] as String,
        createdAt: j['createdAt'] == null
            ? null
            : DateTime.tryParse(j['createdAt'] as String),
      );
}

/// One student's attendance row, as shown on the teacher's attendance screen.
class MeetingAttendanceRow {
  const MeetingAttendanceRow({
    required this.id,
    required this.studentId,
    required this.studentEmail,
    this.joinedAt,
    this.leftAt,
    this.finalStatus,
    required this.presenceChecksTotal,
    required this.presenceChecksWithFace,
  });

  final int id;
  final int studentId;
  final String studentEmail;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  /// 'present' | 'absent' | null (not finalized yet — still in the call)
  final String? finalStatus;
  final int presenceChecksTotal;
  final int presenceChecksWithFace;

  factory MeetingAttendanceRow.fromJson(Map<String, dynamic> j) =>
      MeetingAttendanceRow(
        id: (j['id'] as num).toInt(),
        studentId: (j['studentId'] as num).toInt(),
        studentEmail: j['studentEmail'] as String,
        joinedAt: j['joinedAt'] == null
            ? null
            : DateTime.tryParse(j['joinedAt'] as String),
        leftAt: j['leftAt'] == null
            ? null
            : DateTime.tryParse(j['leftAt'] as String),
        finalStatus: j['finalStatus'] as String?,
        presenceChecksTotal: (j['presenceChecksTotal'] as num?)?.toInt() ?? 0,
        presenceChecksWithFace:
            (j['presenceChecksWithFace'] as num?)?.toInt() ?? 0,
      );
}

class MeetingService {
  MeetingService(this.api);
  final ApiClient api;

  Future<List<Meeting>> list({int? subjectId}) async {
    final path = subjectId == null
        ? '/api/meetings'
        : '/api/meetings?subject_id=$subjectId';
    final res = await api.getAuthed(path);
    return ((res['meetings'] as List?) ?? const [])
        .map((e) => Meeting.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Meeting> detail(int id) async {
    final res = await api.getAuthed('/api/meetings/$id');
    return Meeting.fromJson(res['meeting'] as Map<String, dynamic>);
  }

  Future<Meeting> create({
    required int subjectId,
    required String title,
    required DateTime scheduledAt,
    required int durationMinutes,
  }) async {
    final res = await api.postAuthed('/api/meetings', {
      'subjectId': subjectId,
      'title': title,
      'scheduledAt': scheduledAt.toIso8601String(),
      'durationMinutes': durationMinutes,
    });
    return Meeting.fromJson(res['meeting'] as Map<String, dynamic>);
  }

  Future<void> join(int meetingId) =>
      api.postAuthed('/api/meetings/$meetingId/join', const {});

  Future<void> presenceCheck(int meetingId, {required bool faceDetected}) =>
      api.postAuthed('/api/meetings/$meetingId/presence-check', {
        'faceDetected': faceDetected,
      });

  /// Returns the finalized status ('present' | 'absent').
  Future<String?> leave(int meetingId) async {
    final res =
        await api.postAuthed('/api/meetings/$meetingId/leave', const {});
    return res['finalStatus'] as String?;
  }

  Future<List<MeetingAttendanceRow>> attendance(int meetingId) async {
    final res = await api.getAuthed('/api/meetings/$meetingId/attendance');
    return ((res['attendance'] as List?) ?? const [])
        .map((e) => MeetingAttendanceRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
