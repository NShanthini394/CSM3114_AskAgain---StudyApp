import 'package:material_ui/material_ui.dart';

import '../data/notebook.dart';
import 'common.dart';

String examDate(String value) {
  final date = DateTime.parse(value);
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class ExamEditorPage extends StatefulWidget {
  const ExamEditorPage({super.key, this.exam});
  final StudyRecord? exam;
  @override
  State<ExamEditorPage> createState() => _ExamEditorState();
}

class _ExamEditorState extends State<ExamEditorPage> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.exam?['name'] ?? '');
  late String? subject = widget.exam?['subject'];
  late DateTime? date = widget.exam == null
      ? null
      : DateTime.parse(widget.exam!['date']);
  bool saving = false;
  String error = '';
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam == null ? 'Add Exam' : 'Edit Exam'),
      ),
      body: Form(
        key: form,
        child: PageBody([
          TextFormField(
            controller: name,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Exam Name',
              hintText: 'e.g. Midterm',
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Enter the exam name' : null,
          ),
          DropdownButtonFormField<String>(
            initialValue: book.records.containsKey(subject) ? subject : null,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: [
              for (final s in book.rows('subject'))
                DropdownMenuItem(
                  value: s['id'] as String,
                  child: Text(s['name']),
                ),
            ],
            onChanged: (v) => subject = v,
            validator: (v) => v == null ? 'Choose a subject' : null,
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text(
              date == null ? 'Choose exam date' : examDate(today(date)),
            ),
            onPressed: () async {
              final now = DateTime.now();
              final first = DateTime(now.year, now.month, now.day);
              final initial = date != null && date!.isAfter(first)
                  ? date!
                  : first;
              final d = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: first,
                lastDate: DateTime(now.year + 10),
              );
              if (d != null) setState(() => date = d);
            },
          ),
          if (error.isNotEmpty)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    if (date == null) {
                      setState(() => error = 'Choose an exam date.');
                      return;
                    }
                    setState(() {
                      saving = true;
                      error = '';
                    });
                    try {
                      await book.save({
                        'id': widget.exam?['id'] ?? newId(),
                        'kind': 'exam',
                        'name': name.text.trim(),
                        'subject': subject,
                        'date': today(date),
                      });
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) setState(() => error = e.toString());
                    } finally {
                      if (mounted) setState(() => saving = false);
                    }
                  },
            child: Text(saving ? 'Saving…' : 'Save exam'),
          ),
        ]),
      ),
    );
  }
}
