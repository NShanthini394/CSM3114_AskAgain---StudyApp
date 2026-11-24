import 'package:material_ui/material_ui.dart';

import '../data/notebook.dart';
import '../services/reminders.dart';
import 'chapter_selector.dart';
import 'common.dart';

class QuestionEditor extends StatefulWidget {
  const QuestionEditor({
    super.key,
    required this.subject,
    this.question,
    this.document,
    this.chapter,
  });
  final String subject;
  final StudyRecord? question;
  final String? document, chapter;
  @override
  State<QuestionEditor> createState() => _Editor();
}

class _Editor extends State<QuestionEditor> {
  final form = GlobalKey<FormState>();
  late final prompt = TextEditingController(
    text: widget.question?['studyPrompt'] ?? widget.question?['prompt'] ?? '',
  );
  late final answer = TextEditingController(
    text: widget.question?['answer'] ?? '',
  );
  late String chapter = widget.question?['chapter'] ?? widget.chapter ?? '';
  bool saving = false;
  String error = '';
  @override
  void dispose() {
    prompt.dispose();
    answer.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = '';
    });
    try {
      final book = context.book,
          doc = widget.question?['document'] ?? widget.document;
      final q = <String, dynamic>{
        ...?widget.question,
        'id': widget.question?['id'] ?? newId(),
        'kind': 'question',
        'subject': widget.subject,
        'chapter': chapter,
        'prompt': prompt.text.trim(),
        'studyPrompt': prompt.text.trim(),
        'answer': answer.text.trim(),
        'document': doc,
        'approved': doc == null || book.records[doc]?['final'] == true,
        'due': widget.question?['due'] ?? today(),
      };
      // Retain validated numerical metadata only when its answer scheme is unchanged.
      if (answer.text.trim() != widget.question?['answer']) {
        q.remove('numeric');
        q.remove('unit');
        q.remove('tolerance');
      }
      q['responseFormat'] = q['mode'] == 'Programming'
          ? 'Code answer'
          : q['numeric'] != null
          ? 'Numerical answer'
          : 'Written answer';
      q.remove('blanks');
      q.remove('pairs');
      q.remove('_derived');
      q.remove('_sourceIds');
      await book.save(q);
      await Reminders.refresh(book);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.question == null ? 'New Question' : 'Edit Question'),
      actions: [
        if (widget.question != null)
          IconButton(
            tooltip: 'Delete question',
            icon: const Icon(Icons.delete_outline),
            onPressed: saving
                ? null
                : () async {
                    if (!await confirm(
                      context,
                      'Delete question?',
                      'This removes it from revision.',
                    )) {
                      return;
                    }
                    if (!context.mounted) return;
                    try {
                      await context.book.change([], [widget.question!['id']]);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) context.message(e);
                    }
                  },
          ),
      ],
    ),
    body: Form(
      key: form,
      child: PageBody([
        TextFormField(
          controller: prompt,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Question'),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Enter a question' : null,
        ),
        TextFormField(
          controller: answer,
          minLines: 4,
          maxLines: 10,
          decoration: const InputDecoration(labelText: 'Answer'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Enter an answer' : null,
        ),
        ChapterSelector(
          subject: widget.subject,
          value: chapter,
          onChanged: (v) => setState(() => chapter = v),
        ),
        if (error.isNotEmpty)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Saving…' : 'Save question'),
        ),
      ]),
    ),
  );
}
