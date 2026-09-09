import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';

class TakeQuizScreen extends StatefulWidget {
  const TakeQuizScreen({
    super.key,
    required this.evaluationId,
    required this.title,
    required this.subject,
  });

  final int evaluationId;
  final String title;
  final String subject;

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  final TextEditingController _answerCtrl = TextEditingController();
  bool _submitting = false;
  Map<String, dynamic>? _result;

  String get _sampleQuestion {
    if (widget.subject.toLowerCase().contains('math')) {
      return "Question 1: Explain how to find the roots of a quadratic equation ax² + bx + c = 0, and what the discriminant (b² - 4ac) indicates about the nature of the roots.";
    } else if (widget.subject.toLowerCase().contains('computer')) {
      return "Question 1: What is the difference between a List and a Dictionary (Hash Map) in Python in terms of time complexity for lookups, and when would you choose one over the other?";
    } else {
      return "Question 1: State Newton's Second Law of Motion with its formula. Provide a real-world example of how mass impacts acceleration when force is kept constant.";
    }
  }

  Future<void> _submitAnswers() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your response before submitting')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final res = await apiClient.postAuthed('/api/evaluations/${widget.evaluationId}/submit', {
        'question': _sampleQuestion,
        'answers': text,
      });

      if (res is Map<String, dynamic>) {
        setState(() {
          _result = res;
          _submitting = false;
        });
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit evaluation: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_result != null) ...[
                  _ResultCard(result: _result!, onDone: () => Navigator.pop(context, true)),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.subject,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            const Text('AI Interactive Assessment', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _sampleQuestion,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.4, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Your Answer & Explanation:',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _answerCtrl,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'Type your explanation step-by-step. The AI Grading System will analyze your logic, terminology, and reasoning...',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _submitAnswers,
                            icon: _submitting
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.auto_awesome, size: 18),
                            label: Text(_submitting ? 'AI Grading in Progress...' : 'Submit for AI Evaluation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onDone});
  final Map<String, dynamic> result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final grade = (result['grade'] as num?)?.toDouble() ?? 85.0;
    final feedback = result['feedback']?.toString() ?? 'Evaluation completed successfully.';
    final isPassing = grade >= 75.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isPassing ? const Color(0xFFDDFBE7) : const Color(0xFFFFE9B8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassing ? Icons.check_circle_outline : Icons.stars_outlined,
              color: isPassing ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Evaluation Graded & Saved!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Recorded to Classroom Grades Table',
            style: TextStyle(fontSize: 12.5, color: Colors.black.withOpacity(0.55), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                const Text('AI ASSIGNED SCORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(
                  '${grade.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: isPassing ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Instructor & AI Feedback:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    feedback,
                    style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              child: const Text('Return to Schedule'),
            ),
          ),
        ],
      ),
    );
  }
}
