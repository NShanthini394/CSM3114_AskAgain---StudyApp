import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import 'common.dart';
import 'question_editor.dart';
import '../data/study_content.dart';
import 'chapter_selector.dart';
import 'learning_page.dart';

class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key, required this.subject, this.chapter});
  final String subject;
  final String? chapter;
  @override
  State<QuestionBankPage> createState() => _BankState();
}

class _BankState extends State<QuestionBankPage> {
  String search = '', difficulty = 'All', topic = 'All';
  final selected = <String>{};
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    final questions = scopedQuestions(
      book.questions,
      widget.subject,
      widget.chapter,
    );
    final topics = {
      'All',
      ...questions
          .map((q) => q['topic']?.toString() ?? '')
          .where((t) => t.isNotEmpty),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${book.records[widget.subject]?['name'] ?? 'Subject'} Questions',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add question',
        onPressed: () => context.open(
          QuestionEditor(subject: widget.subject, chapter: widget.chapter),
        ),
        child: const Icon(Icons.add),
      ),
      body: PageBody([
        OutlinedButton.icon(
          onPressed: () => context.open(
            LearningPage(subject: widget.subject, chapter: widget.chapter),
          ),
          icon: const Icon(Icons.menu_book_outlined),
          label: const Text('Read & Learn'),
        ),
        if (selected.isNotEmpty)
          FilledButton(
            onPressed: () async {
              var destination = '';
              final chosen = await showDialog<String>(
                context: context,
                builder: (dialog) => StatefulBuilder(
                  builder: (c, setDialog) => AlertDialog(
                    title: const Text('Move to Chapter'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChapterSelector(
                          subject: widget.subject,
                          value: destination,
                          onChanged: (v) => setDialog(() => destination = v),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialog, destination),
                        child: const Text('Move'),
                      ),
                    ],
                  ),
                ),
              );
              if (chosen == null) return;
              try {
                await book.change([
                  for (final id in selected)
                    if (book.records[id] != null)
                      {...book.records[id]!, 'chapter': chosen},
                ], []);
                if (mounted) setState(() => selected.clear());
              } catch (e) {
                if (context.mounted) context.message(e);
              }
            },
            child: Text('Move ${selected.length} selected to chapter'),
          ),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search questions',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
        ),
        DropdownButtonFormField(
          initialValue: topics.contains(topic) ? topic : 'All',
          decoration: const InputDecoration(labelText: 'Topic'),
          items: [
            for (final t in topics) DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: (v) => setState(() => topic = v!),
        ),
        DropdownButtonFormField(
          initialValue: difficulty,
          decoration: const InputDecoration(
            labelText: 'Difficulty or progress',
          ),
          items: [
            for (final t in [
              'All',
              'Easy',
              'Medium',
              'Hard',
              'Weak',
              'Mastered',
            ])
              DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: (v) => setState(() => difficulty = v!),
        ),
        Text('${questions.length} questions ready for revision'),
        for (final q in questions.where(
          (q) =>
              ('${q['prompt']} ${q['topic']}').toLowerCase().contains(search) &&
              (topic == 'All' || q['topic'] == topic) &&
              (difficulty == 'All' ||
                  q['difficulty'] == difficulty ||
                  difficulty == 'Weak' && (q['rating'] ?? 4) < 2 ||
                  difficulty == 'Mastered' && q['rating'] == 3),
        ))
          Card(
            child: ListTile(
              leading: Checkbox(
                value: selected.contains(q['id']),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    selected.add(q['id']);
                  } else {
                    selected.remove(q['id']);
                  }
                }),
              ),
              title: Text(q['prompt']),
              subtitle: Text(
                '${q['topic'] ?? 'General'} • ${q['difficulty'] ?? 'Medium'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.open(
                QuestionEditor(subject: widget.subject, question: q),
              ),
            ),
          ),
        if (questions.isEmpty)
          const Text('Write a question or finalise a generated set to begin.'),
      ]),
    );
  }
}
