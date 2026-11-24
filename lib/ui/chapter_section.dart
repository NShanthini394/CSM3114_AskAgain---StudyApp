import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import '../data/study_content.dart';
import 'common.dart';
import 'chapter_selector.dart';
import 'chapter_page.dart';

class ChapterSection extends StatelessWidget {
  const ChapterSection({super.key, required this.subject});
  final String subject;
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>(),
        chapters = book
            .rows('chapter')
            .where((c) => c['subject'] == subject)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TitleLine('Chapters'),
        TextButton.icon(
          onPressed: () async {
            final name = await input(context, 'Chapter name');
            if (name != null) {
              try {
                await book.save({
                  'id': newId(),
                  'kind': 'chapter',
                  'subject': subject,
                  'name': name,
                });
              } catch (e) {
                if (context.mounted) context.message(e);
              }
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Add chapter'),
        ),
        for (final chapter in [
          {'id': '', 'name': 'Unassigned chapter'},
          ...chapters,
        ])
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(chapter['name']),
            subtitle: Text(
              '${scopedQuestions(book.questions, subject, chapter['id']).length} questions',
            ),
            onTap: () => context.open(
              ChapterPage(subject: subject, chapter: chapter['id']),
            ),
            trailing: chapter['id'] == ''
                ? null
                : PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      for (final a in ['Rename', 'Remove'])
                        PopupMenuItem(value: a, child: Text(a)),
                    ],
                    onSelected: (action) =>
                        manageChapter(context, chapter, action),
                  ),
          ),
      ],
    );
  }
}
