import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import 'common.dart';
import 'review_page.dart';

class NoteReviewsPage extends StatelessWidget {
  const NoteReviewsPage({super.key, required this.subject});
  final String subject;
  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>(),
        notes = book
            .rows('document')
            .where((d) => d['subject'] == subject)
            .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Note Reviews')),
      body: PageBody([
        if (notes.isEmpty)
          const Text('Uploaded note reviews will appear here.'),
        for (final note in notes.reversed)
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(note['name']),
            subtitle: Text(
              note['final'] == true
                  ? 'Ready for study'
                  : 'Draft • review before studying',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.open(ReviewPage(id: note['id'])),
          ),
      ]),
    );
  }
}
