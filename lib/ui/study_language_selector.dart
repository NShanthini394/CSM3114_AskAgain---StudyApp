import 'package:material_ui/material_ui.dart';

import '../data/study_languages.dart';

class StudyLanguageSelector extends StatelessWidget {
  const StudyLanguageSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Preferred study language',
  });
  final String value, label;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final selected = normaliseStudyLanguage(value);
    return DropdownButtonFormField<String>(
      key: ValueKey(selected),
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Use the notes’ language, or choose a translation. App menus are in English.',
        helperMaxLines: 3,
      ),
      items: [
        for (final language in availableStudyLanguages(selected))
          DropdownMenuItem(value: language, child: Text(language)),
      ],
      onChanged: (language) {
        if (language != null) onChanged(language);
      },
    );
  }
}
