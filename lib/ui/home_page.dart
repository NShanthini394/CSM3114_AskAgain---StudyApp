import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import 'common.dart';
import 'subjects_page.dart';
import 'progress_page.dart';
import 'profile_page.dart';
import 'exams_page.dart';
import 'upload_page.dart';
import 'generation_status.dart';
import 'exam_editor_page.dart';
import 'attention_page.dart';
import 'practice_page.dart';
import 'subject_folders.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    return Scaffold(
      appBar: AppBar(
        title: Text(['AskAgain', 'Subjects', 'Revision', 'Progress'][index]),
        actions: [
          const GenerationStatusAction(),
          IconButton(
            tooltip: 'Exams',
            onPressed: () => context.open(const ExamsPage()),
            icon: const Icon(Icons.event_outlined),
          ),
          IconButton(
            tooltip: 'Profile and settings',
            onPressed: () => context.open(const ProfilePage()),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: switch (index) {
        1 => const SubjectsPage(),
        2 => PageBody([
          const TitleLine('Revision Queue'),
          Text('${book.due.length} questions due today'),
          FilledButton(
            onPressed: () => context.open(const PracticePage(dueOnly: true)),
            child: const Text('Open Revision'),
          ),
          const NeedsAttentionSection(),
          const TitleLine('Revise by Subject'),
          SubjectFolders(
            subjects: book.rows('subject'),
            questions: book.questions,
            onOpen: (s) => context.open(PracticePage(subject: s['id'])),
          ),
        ]),
        3 => const ProgressPage(),
        _ => PageBody([
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today’s Revision'),
                const SizedBox(height: 12),
                TitleLine(
                  '${book.due.length} ${book.due.length == 1 ? 'Question' : 'Questions'} Due',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: book.due.isEmpty
                      ? null
                      : () => context.open(const PracticePage(dueOnly: true)),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Revision'),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              if (book.rows('subject').isEmpty) {
                final s = await input(context, 'Name your first subject');
                if (s == null) return;
                await book.save({'id': newId(), 'kind': 'subject', 'name': s});
              }
              if (context.mounted) {
                context.open(
                  UploadPage(subject: book.rows('subject').first['id']),
                );
              }
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Create questions from notes'),
          ),
          const TitleLine('Your Subjects'),
          SubjectFolders(
            subjects: book.rows('subject'),
            questions: book.questions,
            onOpen: (s) => context.open(SubjectPage(id: s['id'])),
          ),
          if (book.rows('subject').isEmpty)
            const Text(
              'Add your first subject to organise notes and revision questions.',
            ),
          const TitleLine('Upcoming Exams'),
          if (!book.rows('exam').any((e) => e['date'].compareTo(today()) >= 0))
            TextButton(
              onPressed: () => context.open(const ExamsPage()),
              child: const Text('Add an exam goal'),
            ),
          for (final e
              in (book
                  .rows('exam')
                  .where((e) => e['date'].compareTo(today()) >= 0)
                  .toList()
                ..sort((a, b) => a['date'].compareTo(b['date']))))
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(e['name']),
              subtitle: Text(
                '${book.records[e['subject']]?['name'] ?? 'Subject'} • ${examDate(e['date'])}',
              ),
              onTap: () => context.open(const ExamsPage()),
            ),
        ]),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            label: 'Subjects',
          ),
          NavigationDestination(icon: Icon(Icons.replay), label: 'Revision'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Progress'),
        ],
      ),
    );
  }
}
