import '../../core/network/api_client.dart';

class Booking {
  const Booking({
    required this.id,
    required this.title,
    required this.teacher,
    required this.room,
    required this.weekday, // 1 = Mon … 5 = Fri
    required this.startHour, // 24h
    required this.endHour,
  });

  final int id;
  final String title;
  final String teacher;
  final String room;
  final int weekday;
  final int startHour;
  final int endHour;

  int get durationHours => (endHour - startHour).clamp(1, 12);

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String,
        teacher: j['teacher'] as String,
        room: (j['room'] ?? 'Room 301') as String,
        weekday: (j['weekday'] as num).toInt(),
        startHour: (j['startHour'] as num).toInt(),
        endHour: (j['endHour'] as num).toInt(),
      );
}

class ScheduleService {
  ScheduleService(this.api);
  final ApiClient api;

  Future<List<Booking>> bookings() async {
    final res = await api.getAuthed('/api/schedule');
    return ((res['bookings'] as List?) ?? const [])
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> create({
    required String title,
    required String teacher,
    required String room,
    required int weekday,
    required int startHour,
    required int endHour,
  }) async {
    final res = await api.postAuthed('/api/schedule', {
      'title': title,
      'teacher': teacher,
      'room': room,
      'weekday': weekday,
      'startHour': startHour,
      'endHour': endHour,
    });
    return Booking.fromJson(res['booking'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => api.deleteAuthed('/api/schedule/$id');
}
