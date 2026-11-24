import 'package:material_ui/material_ui.dart';

import '../data/notebook.dart';
import '../data/subject_styles.dart';
import 'app_palette.dart';

class SubjectFolders extends StatelessWidget {
  const SubjectFolders({
    super.key,
    required this.subjects,
    required this.questions,
    required this.onOpen,
  });
  final List<StudyRecord> subjects, questions;
  final ValueChanged<StudyRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette(Theme.of(context).brightness == Brightness.dark);
    final counts = <String, int>{};
    for (final question in questions) {
      final id = question['subject'];
      if (id is String) counts[id] = (counts[id] ?? 0) + 1;
    }
    return LayoutBuilder(
      builder: (context, space) {
        // Preserve reading space when Android accessibility text is very large.
        final columns =
            space.maxWidth >= 280 &&
                MediaQuery.textScalerOf(context).scale(16) <= 28
            ? 2
            : 1;
        final width = (space.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final subject in subjects)
              SizedBox(
                width: width,
                child: Card(
                  margin: EdgeInsets.zero,
                  color: palette.folder(subjectColour(subject)),
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpen(subject),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 152),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.folder_rounded,
                              size: 36,
                              color: palette.folderAccent(
                                subjectColour(subject),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              subject['name'],
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.text,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${counts[subject['id']] ?? 0} ${(counts[subject['id']] ?? 0) == 1 ? 'question' : 'questions'}',
                              style: TextStyle(color: palette.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
