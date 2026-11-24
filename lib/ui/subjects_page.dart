import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import 'common.dart';
import 'note_reviews_page.dart';
import 'question_bank_page.dart';
import 'chapter_section.dart';
import 'learning_page.dart';
import 'practice_page.dart';
import 'subject_folders.dart';
import 'create_question_page.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    return PageBody([
      FilledButton.icon(
        onPressed: () async {
          final name = await input(context, 'Subject name');
          if (name != null) {
            await book.save({'id': newId(), 'kind': 'subject', 'name': name});
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      SubjectFolders(
        subjects: book.rows('subject'),
        questions: book.questions,
        onOpen: (s) => context.open(SubjectPage(id: s['id'])),
      ),
    ]);
  }
}

class SubjectPage extends StatelessWidget {
  const SubjectPage({super.key, required this.id});
  final String id;
  Future<void> modify(BuildContext context, String action) async {
    final book = context.book, subject = book.records[id]!;
    try {
      if (action == 'Rename') {
        final name = await input(context, 'Rename subject', subject['name']);
        if (name != null) await book.save({...subject, 'name': name});
      } else if (await confirm(
        context,
        'Delete subject?',
        'Its questions, notes, exams and history will also be deleted.',
      )) {
        final receipts = book
            .rows('document')
            .where((d) => d['subject'] == id)
            .map(
              (d) => <String, dynamic>{
                'id': d['id'],
                'kind': 'generationReceipt',
              },
            )
            .toList();
        final retain = receipts.map((r) => r['id']).toSet();
        final remove = book.records.values
            .where(
              (r) =>
                  (r['subject'] == id || r['id'] == id) &&
                  !retain.contains(r['id']),
            )
            .map((r) => r['id'] as String)
            .toList();
        await book.change(receipts, remove);
        if (context.mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) context.message(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>(), subject = book.records[id];
    if (subject == null) return const SizedBox();
    final count = book.questions.where((q) => q['subject'] == id).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(subject['name']),
        actions: [
          IconButton(
            tooltip: 'Note reviews',
            onPressed: () => context.open(NoteReviewsPage(subject: id)),
            icon: const Icon(Icons.description_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => modify(context, v),
            itemBuilder: (_) => [
              for (final a in ['Rename', 'Delete'])
                PopupMenuItem(value: a, child: Text(a)),
            ],
          ),
        ],
      ),
      body: PageBody([
        FilledButton.icon(
          onPressed: () => context.open(LearningPage(subject: id)),
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('Read & Learn'),
        ),
        OutlinedButton.icon(
          onPressed: count == 0
              ? null
              : () => context.open(PracticePage(subject: id)),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Practice'),
        ),
        ChapterSection(subject: id),
        OutlinedButton.icon(
          onPressed: () => context.open(QuestionBankPage(subject: id)),
          icon: const Icon(Icons.quiz_outlined),
          label: Text('View questions ($count)'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.open(CreateQuestionPage(subject: id)),
          icon: const Icon(Icons.add),
          label: const Text('Add question'),
        ),
      ]),
    );
  }
}
