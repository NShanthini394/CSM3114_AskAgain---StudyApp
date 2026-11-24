import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import '../data/study_content.dart';
import 'common.dart';
import 'learning_page.dart';
import 'practice_page.dart';
import 'question_bank_page.dart';
import 'create_question_page.dart';

class ChapterPage extends StatelessWidget {
  const ChapterPage({super.key, required this.subject, required this.chapter});
  final String subject, chapter;
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    final title = chapter.isEmpty
        ? 'Unassigned Chapter'
        : book.records[chapter]?['name'] ?? 'Chapter';
    final count = scopedQuestions(book.questions, subject, chapter).length;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PageBody([
        FilledButton.icon(
          onPressed: count == 0
              ? null
              : () => context.open(
                  LearningPage(subject: subject, chapter: chapter),
                ),
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('Read & Learn'),
        ),
        OutlinedButton.icon(
          onPressed: count == 0
              ? null
              : () => context.open(
                  PracticePage(subject: subject, chapter: chapter),
                ),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Practice'),
        ),
        Text('$count ${count == 1 ? 'question' : 'questions'} in this chapter'),
        OutlinedButton.icon(
          onPressed: () => context.open(
            QuestionBankPage(subject: subject, chapter: chapter),
          ),
          icon: const Icon(Icons.list_alt),
          label: const Text('Manage questions'),
        ),
        TextButton.icon(
          onPressed: () => context.open(
            CreateQuestionPage(subject: subject, chapter: chapter),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add question'),
        ),
      ]),
    );
  }
}
