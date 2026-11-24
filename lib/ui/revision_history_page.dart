import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import '../data/study_content.dart';
import 'common.dart';

class RevisionHistoryPage extends StatelessWidget {
  const RevisionHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>(),
        sessions = revisionSessions(book.rows('attempt'));
    return Scaffold(
      appBar: AppBar(title: const Text('Revision History')),
      body: PageBody([
        if (sessions.isEmpty)
          const Text('Completed practice will appear here.'),
        for (final session in sessions) SessionTile(session: session),
      ]),
    );
  }
}

class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session});
  final StudyRecord session;
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>(),
        attempts = session['attempts'] as List;
    final subject =
        book.records[session['subject']]?['name'] ?? 'Deleted subject';
    final chapter = book.records[session['chapter']]?['name'];
    final time = DateTime.tryParse(session['timestamp'])?.toLocal();
    final stamp = time == null ? '' : time.toString().substring(0, 16);
    return Card(
      child: ListTile(
        title: Text('$subject${chapter == null ? '' : ' • $chapter'}'),
        subtitle: Text(
          '$stamp\n${attempts.first['activity'] == 'recall' ? 'Learn & Recall' : 'Practice'} • ${attempts.length} reviewed • ${session['needsPractice']} need practice',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.open(SessionDetailsPage(session: session)),
      ),
    );
  }
}

class SessionDetailsPage extends StatelessWidget {
  const SessionDetailsPage({super.key, required this.session});
  final StudyRecord session;
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: PageBody([
        for (final a in session['attempts'])
          Card(
            child: ExpansionTile(
              title: Text(
                a['prompt'] ??
                    book.records[a['question']]?['studyPrompt'] ??
                    book.records[a['question']]?['prompt'] ??
                    'Deleted question',
              ),
              subtitle: Text(ratings[a['rating']]),
              childrenPadding: const EdgeInsets.all(16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Response',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SelectableText(
                  (a['response'] ?? '').isEmpty
                      ? 'No answer recorded'
                      : a['response'],
                ),
                if ((a['mistake'] ?? '') != '')
                  Text('Difficulty: ${a['mistake']}'),
              ],
            ),
          ),
      ]),
    );
  }
}
