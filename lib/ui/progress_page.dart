import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import '../data/study_content.dart';
import 'common.dart';
import 'revision_history_page.dart';
import 'chapter_page.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>(),
        attempts = book.rows('attempt'),
        sessions = revisionSessions(book.rows('attempt'));
    final days = attempts.map((a) => a['date']).toSet().length;
    return PageBody([
      Text(
        '${book.questions.length} questions • ${book.due.length} due • $days study ${days == 1 ? 'day' : 'days'}',
      ),
      const TitleLine('Subject Progress'),
      for (final subject in book.rows('subject'))
        Builder(
          builder: (_) {
            final questions = book.questions
                .where((q) => q['subject'] == subject['id'])
                .toList();
            final mastered = questions.where((q) => q['rating'] == 3).length;
            return Card(
              child: ExpansionTile(
                title: Text(subject['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$mastered of ${questions.length} mastered'),
                    LinearProgressIndicator(
                      value: questions.isEmpty
                          ? 0
                          : mastered / questions.length,
                    ),
                  ],
                ),
                children: [
                  for (final chapter in [
                    {'id': '', 'name': 'Unassigned chapter'},
                    ...book
                        .rows('chapter')
                        .where((c) => c['subject'] == subject['id']),
                  ])
                    Builder(
                      builder: (_) {
                        final content = scopedQuestions(
                          questions,
                          subject['id'],
                          chapter['id'],
                        );
                        if (content.isEmpty) return const SizedBox.shrink();
                        return ListTile(
                          title: Text(chapter['name']),
                          subtitle: Text(
                            '${content.where((q) => q['rating'] == 3).length} of ${content.length} mastered',
                          ),
                          onTap: () => context.open(
                            ChapterPage(
                              subject: subject['id'],
                              chapter: chapter['id'],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      const TitleLine('Recent Sessions'),
      if (sessions.isEmpty)
        const Text('Your revision sessions will appear here.'),
      for (final session in sessions.take(3)) SessionTile(session: session),
      TextButton(
        onPressed: () => context.open(const RevisionHistoryPage()),
        child: const Text('View history'),
      ),
    ]);
  }
}
