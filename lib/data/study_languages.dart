const studyLanguages = [
  'Same as uploaded notes',
  'English',
  'Bahasa Melayu',
  'Tamil',
  'Simplified Chinese',
];

String normaliseStudyLanguage(String? value) => switch (value?.trim()) {
  null || '' || 'Same as notes' => studyLanguages.first,
  'Malay' => 'Bahasa Melayu',
  'Chinese' => 'Simplified Chinese',
  final String language => language,
};
List<String> availableStudyLanguages(String? saved) =>
    {...studyLanguages, normaliseStudyLanguage(saved)}.toList();

String generationLanguageInstruction(String? selected) {
  final language = normaliseStudyLanguage(selected);
  return language == studyLanguages.first
      ? 'Write each question and its answer in the language of its supporting source passage. For multilingual notes, follow the language of each passage. Preserve technical terms, formulas and code. Do not translate the evidence.'
      : 'Write both questions and answers in $language. Preserve the source meaning, technical terms, formulas and code. Keep evidence quoted exactly in its original source language.';
}
