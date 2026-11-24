import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/attention.dart';
import '../data/notebook.dart';
import '../data/heading_case.dart';
import 'common.dart';
import 'learning_page.dart';
import 'practice_page.dart';

class NeedsAttentionSection extends StatelessWidget {
  const NeedsAttentionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    final groups = attentionGroups(book.questions, book.rows('attempt'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitleLine('Needs Attention'),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          const Text(
            'Record what was difficult after a practice question. '
            'Your questions will appear here for focused revision.',
          )
        else ...[
          const Text('Tap a difficulty to learn or practise its questions.'),
          for (final group in groups)
            Card(
              child: ListTile(
                title: Text(headingCase(group.reason)),
                subtitle: Text(
                  '${group.questions.length} ${group.questions.length == 1 ? 'question' : 'questions'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.open(AttentionPage(reason: group.reason)),
              ),
            ),
        ],
      ],
    );
  }
}

class AttentionPage extends StatelessWidget {
  const AttentionPage({super.key, required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    final groups = attentionGroups(book.questions, book.rows('attempt'));
    final content = groups
        .where((group) => group.reason == reason)
        .expand((group) => group.questions)
        .toList();
    final ids = content.map((q) => q['id'] as String).toSet();
    return Scaffold(
      appBar: AppBar(title: Text(headingCase(reason))),
      body: PageBody([
        if (content.isEmpty)
          const Text('No questions currently need attention in this category.')
        else ...[
          TitleLine(
            '${content.length} ${content.length == 1 ? 'Question Needs' : 'Questions Need'} Attention',
          ),
          const Text(
            'Based on each question’s latest practice difficulty. '
            'Repeated attempts count once. A new practice attempt replaces '
            'the previous difficulty; mastered questions leave this list.',
          ),
          FilledButton.icon(
            onPressed: () => context.open(LearningPage(questionIds: ids)),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Learn these questions'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.open(PracticePage(questionIds: ids)),
            icon: const Icon(Icons.edit_note),
            label: const Text('Practise these questions'),
          ),
          for (final question in content)
            Card(
              child: ListTile(
                title: Text(question['studyPrompt'] ?? question['prompt']),
                subtitle: Text(
                  '${book.records[question['subject']]?['name'] ?? 'Subject'} • '
                  '${book.records[question['chapter']]?['name'] ?? 'Unassigned chapter'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.open(
                  LearningPage(questionIds: {question['id'] as String}),
                ),
              ),
            ),
        ],
      ]),
    );
  }
}
