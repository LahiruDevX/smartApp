import 'package:flutter/material.dart';
import '../../core/di/app_di.dart';

class TakeQuizScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;

  const TakeQuizScreen({super.key, required this.quiz});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  final _answerController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  Future<void> _submitAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await apiClient.postAuthed('/api/ai/grade', {
        'evaluationId': widget.quiz['id'],
        'studentAnswer': answer,
      });

      if (mounted) {
        setState(() {
          _result = res['evaluation'];
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz: ${widget.quiz['title']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject: ${widget.quiz['subject']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  const SizedBox(height: 8),
                  const Text('Please write a detailed explanation based on the class materials for the topic.', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (_result != null) ...[
              // Results View
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDFBE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
                        const SizedBox(width: 12),
                        Text('Grade: ${_result!['grade']}/100', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('AI Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_result!['feedback'] ?? '', style: const TextStyle(height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to Dashboard'),
                ),
              ),
            ] else ...[
              // Answer View
              TextField(
                controller: _answerController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Your Answer',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit to AI Teacher for Grading'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
