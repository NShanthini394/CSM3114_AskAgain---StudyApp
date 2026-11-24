import 'package:material_ui/material_ui.dart';

import 'common.dart';
import 'question_editor.dart';
import 'upload_page.dart';

class CreateQuestionPage extends StatelessWidget {
  const CreateQuestionPage({super.key, required this.subject, this.chapter});

  final String subject;
  final String? chapter;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Question')),
    body: PageBody([
      const TitleLine('How Would You Like to Create Questions?'),
      ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: const Text('Write Q&A Manually'),
        subtitle: const Text('Enter your own question and answer.'),
        onTap: () =>
            context.open(QuestionEditor(subject: subject, chapter: chapter)),
      ),
      ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: const Text('Upload PDF Notes with AI'),
        subtitle: const Text('Choose a PDF and generate a question set.'),
        onTap: () => context.open(
          UploadPage(subject: subject, chapter: chapter, input: NotesInput.pdf),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.content_paste_outlined),
        title: const Text('Paste Notes with AI'),
        subtitle: const Text('Paste text and generate a question set.'),
        onTap: () => context.open(
          UploadPage(
            subject: subject,
            chapter: chapter,
            input: NotesInput.text,
          ),
        ),
      ),
    ]),
  );
}
