import 'package:flutter/material.dart';

import '../../core/di/app_di.dart';
import '../../features/study_helper/study_helper_service.dart';
import '../theme/chalk_shapes.dart';
import '../theme/chalk_theme.dart';

/// A general-purpose "ask anything" study buddy for students — separate from
/// the per-subject 3D AI Teacher, and not tied to a subject or lesson.
/// Pushed as its own screen (like ai_chat_screen.dart) rather than a named
/// AppShell route, since a full-height chat list needs its own Scaffold.
class StudyHelperScreen extends StatefulWidget {
  const StudyHelperScreen({super.key});

  @override
  State<StudyHelperScreen> createState() => _StudyHelperScreenState();
}

class _Msg {
  const _Msg(this.isUser, this.text);
  final bool isUser;
  final String text;
}

class _StudyHelperScreenState extends State<StudyHelperScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    const _Msg(false,
        "Hi! I'm your Study Helper. Ask me anything you're stuck on — homework, "
        "a concept from class, or just something you're curious about."),
  ];
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    final history = [
      for (final m in _msgs)
        StudyHelperMessage(role: m.isUser ? 'user' : 'model', content: m.text),
    ];

    setState(() {
      _msgs.add(_Msg(true, text));
      _input.clear();
      _sending = true;
      _error = null;
    });
    _jump();

    try {
      final reply = await studyHelperService.ask(text, history: history);
      if (!mounted) return;
      setState(() {
        _msgs.add(_Msg(false, reply));
        _sending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = "I couldn't get an answer just now. Please try again.";
        _sending = false;
      });
    }
    _jump();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChalkColors.paper,
      appBar: AppBar(
        backgroundColor: ChalkColors.chalkboard,
        foregroundColor: Colors.white,
        title: Text('Study Helper',
            style: ChalkText.heading(size: 18, color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(14),
              itemCount: _msgs.length + (_sending ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _msgs.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text('Thinking…', style: ChalkText.body(size: 12.5)),
                      ],
                    ),
                  );
                }
                return _MessageBubble(msg: _msgs[i]);
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ChalkColors.chalkCoral.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: ChalkColors.chalkCoral),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!, style: ChalkText.body(size: 12))),
                  ],
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      style: ChalkText.body(size: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Ask anything…',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChalkTapScale(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: ChalkColors.chalkboard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ClipPath(
          clipper: ChatBubbleClipper(alignRight: msg.isUser, tailInset: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            color: msg.isUser
                ? ChalkColors.chalkboard
                : ChalkColors.chalkSky.withOpacity(0.14),
            child: Text(
              msg.text,
              style: ChalkText.body(
                size: 13.5,
                color: msg.isUser ? Colors.white : ChalkColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
