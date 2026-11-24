import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import '../data/subject_styles.dart';
import '../services/reminders.dart';
import 'app_palette.dart';
import 'common.dart';
import 'question_editor.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final b = context.watch<Notebook>(), d = b.records[id]!;
    final rows = b.rows('question').where((q) => q['document'] == id).toList();
    final palette = AppPalette(Theme.of(context).brightness == Brightness.dark);
    final colour = subjectColour(b.records[d['subject']]);
    return Scaffold(
      appBar: AppBar(title: const Text('Review Question Set')),
      body: PageBody([
        TitleLine(d['name']),
        Text(
          '${rows.length} questions • ${d['final'] == true ? 'Ready for revision' : 'Draft'}',
        ),
        OutlinedButton.icon(
          onPressed: () => context.open(
            QuestionEditor(
              subject: d['subject'],
              document: id,
              chapter: d['chapter'],
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add a question'),
        ),
        if (rows.any(
          (q) =>
              (q['suggestedChapter'] ?? '').toString().trim().isNotEmpty &&
              (q['chapter'] ?? '') == '',
        ))
          OutlinedButton(
            onPressed: () async {
              final labels = rows
                  .where((q) => (q['chapter'] ?? '') == '')
                  .map((q) => (q['suggestedChapter'] ?? '').toString().trim())
                  .where((v) => v.isNotEmpty)
                  .toSet();
              if (!await confirm(
                context,
                'Organise suggested chapters?',
                labels
                    .map(
                      (name) =>
                          '$name • ${rows.where((q) => (q['suggestedChapter'] ?? '').toString().trim() == name).length} questions',
                    )
                    .join('\n'),
              )) {
                return;
              }
              final chapters = <String, String>{};
              final updates = <StudyRecord>[];
              for (final name in labels) {
                final existing = b
                    .rows('chapter')
                    .where(
                      (c) =>
                          c['subject'] == d['subject'] &&
                          c['name'].toString().toLowerCase() ==
                              name.toLowerCase(),
                    )
                    .toList();
                final chapter = existing.isEmpty
                    ? newId()
                    : existing.first['id'] as String;
                chapters[name] = chapter;
                if (existing.isEmpty) {
                  updates.add({
                    'id': chapter,
                    'kind': 'chapter',
                    'name': name,
                    'subject': d['subject'],
                  });
                }
              }
              for (final q in rows) {
                final chapter =
                    chapters[(q['suggestedChapter'] ?? '').toString().trim()];
                if ((q['chapter'] ?? '') == '' && chapter != null) {
                  updates.add({...q, 'chapter': chapter});
                }
              }
              try {
                await b.change(updates, []);
              } catch (e) {
                if (context.mounted) context.message(e);
              }
            },
            child: const Text('Review suggested chapter grouping'),
          ),
        for (final q in rows)
          Card(
            color: palette.folder(colour),
            child: ExpansionTile(
              iconColor: palette.folderAccent(colour),
              collapsedIconColor: palette.folderAccent(colour),
              textColor: palette.text,
              collapsedTextColor: palette.text,
              title: Text(q['prompt']),
              subtitle: Text(
                '${b.records[q['chapter']]?['name'] ?? 'Unassigned chapter'} • ${q['topic'] ?? ''} • ${q['difficulty'] ?? 'Manual'}',
              ),
              childrenPadding: const EdgeInsets.all(16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(q['answer']),
                if (d['final'] != true)
                  CheckboxListTile(
                    value: q['include'] != false,
                    onChanged: (v) => b.save({...q, 'include': v == true}),
                    title: const Text('Include in Revision'),
                    subtitle: Text(
                      q['include'] == false
                          ? 'Held for correction'
                          : 'Included when you finalise this set',
                    ),
                  ),
                if (q['evidence'] != null)
                  Text('\nSource • page ${q['page']}\n${q['evidence']}'),
                TextButton(
                  onPressed: () => context.open(
                    QuestionEditor(subject: d['subject'], question: q),
                  ),
                  child: const Text('Edit or remove'),
                ),
              ],
            ),
          ),
        if (d['final'] != true)
          FilledButton(
            onPressed: rows.every((q) => q['include'] == false)
                ? null
                : () async {
                    if (await confirm(
                      context,
                      'Finalise for revision?',
                      'Approve these ${rows.length} questions and add them to your revision queue.',
                    )) {
                      await b.change([
                        {...d, 'final': true},
                        for (final q in rows)
                          {...q, 'approved': q['include'] != false},
                      ], []);
                      await Reminders.refresh(b);
                    }
                  },
            child: const Text('Finalise for revision'),
          ),
      ]),
    );
  }
}
