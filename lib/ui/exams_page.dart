import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import 'common.dart';
import 'practice_page.dart';
import 'exam_editor_page.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>(),
        exams = book.rows('exam')
          ..sort((a, b) => a['date'].compareTo(b['date']));
    final now = DateTime.parse(today());
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Goals')),
      body: PageBody([
        FilledButton.icon(
          onPressed: book.rows('subject').isEmpty
              ? null
              : () => context.open(const ExamEditorPage()),
          icon: const Icon(Icons.add),
          label: const Text('Add exam'),
        ),
        if (book.rows('subject').isEmpty)
          const Text('Create a subject before scheduling an exam.'),
        if (exams.isEmpty)
          const Text(
            'Your scheduled exams will appear here with their subjects.',
          ),
        for (final exam in exams)
          Builder(
            builder: (_) {
              final questions = book.questions
                  .where((q) => q['subject'] == exam['subject'])
                  .toList();
              final understood = questions
                  .where((q) => (q['rating'] ?? -1) >= 2)
                  .length;
              final days = DateTime.parse(exam['date']).difference(now).inDays;
              final remaining = days < 0
                  ? 'Completed'
                  : days == 0
                  ? 'Today'
                  : days == 1
                  ? 'Tomorrow'
                  : '$days days remaining';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TitleLine(exam['name']),
                      const SizedBox(height: 8),
                      Text(
                        'Subject: ${book.records[exam['subject']]?['name'] ?? 'Unavailable subject'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text('${examDate(exam['date'])} • $remaining'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: questions.isEmpty
                            ? 0
                            : understood / questions.length,
                      ),
                      Text(
                        '$understood of ${questions.length} questions understood or mastered',
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: questions.isEmpty
                                ? null
                                : () => context.open(
                                    PracticePage(subject: exam['subject']),
                                  ),
                            child: const Text('Revise Subject'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.open(ExamEditorPage(exam: exam)),
                            child: const Text('Edit'),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (await confirm(
                                context,
                                'Delete exam?',
                                exam['name'],
                              )) {
                                try {
                                  await book.change([], [exam['id']]);
                                } catch (e) {
                                  if (context.mounted) context.message(e);
                                }
                              }
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ]),
    );
  }
}
