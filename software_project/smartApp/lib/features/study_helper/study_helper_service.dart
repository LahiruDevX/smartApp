import '../../core/network/api_client.dart';

/// One turn of the Study Helper conversation, sent back as `history` so the
/// backend (stateless — nothing is persisted server-side for this feature)
/// can keep context across turns.
class StudyHelperMessage {
  const StudyHelperMessage({required this.role, required this.content});

  /// 'user' or 'model'.
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class StudyHelperService {
  StudyHelperService(this.api);
  final ApiClient api;

  Future<String> ask(
    String message, {
    List<StudyHelperMessage> history = const [],
  }) async {
    final res = await api.postAuthed('/api/study-helper/ask', {
      'message': message,
      if (history.isNotEmpty)
        'history': history.map((h) => h.toJson()).toList(),
    });
    final reply = (res['reply'] as String?)?.trim();
    if (reply == null || reply.isEmpty) {
      throw Exception('The AI model returned an empty response.');
    }
    return reply;
  }
}
