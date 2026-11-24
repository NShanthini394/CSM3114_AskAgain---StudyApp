import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import 'common.dart';

class ChapterSelector extends StatelessWidget {
  const ChapterSelector({
    super.key,
    required this.subject,
    required this.value,
    required this.onChanged,
  });
  final String subject;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    final chapters = book
        .rows('chapter')
        .where((c) => c['subject'] == subject)
        .toList();
    final chosen = chapters.any((c) => c['id'] == value) ? value : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('$subject-$chosen'),
          initialValue: chosen,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Chapter'),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Unassigned chapter'),
            ),
            for (final c in chapters)
              DropdownMenuItem(
                value: c['id'] as String,
                child: Text(c['name']),
              ),
          ],
          onChanged: (v) => onChanged(v!),
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add chapter'),
          onPressed: () async {
            final name = await input(context, 'Chapter name');
            if (name == null) return;
            try {
              final id = newId();
              await book.save({
                'id': id,
                'kind': 'chapter',
                'subject': subject,
                'name': name,
              });
              onChanged(id);
            } catch (e) {
              if (context.mounted) context.message(e);
            }
          },
        ),
      ],
    );
  }
}

Future<void> manageChapter(
  BuildContext context,
  StudyRecord chapter,
  String action,
) async {
  final book = context.book;
  try {
    if (action == 'Rename') {
      final name = await input(context, 'Chapter name', chapter['name']);
      if (name != null) await book.save({...chapter, 'name': name});
    } else if (await confirm(
      context,
      'Remove chapter?',
      'Its questions and notes will move to Unassigned chapter.',
    )) {
      final updates = book.records.values
          .where((r) => r['chapter'] == chapter['id'])
          .map((r) => <String, dynamic>{...r, 'chapter': ''})
          .toList();
      await book.change(updates, [chapter['id']]);
    }
  } catch (e) {
    if (context.mounted) context.message(e);
  }
}
