const studyFontFamilies = [
  'Inter',
  'Roboto',
  'Open Sans',
  'Lexend',
  'Libre Baskerville',
];
const studyTextSizes = {
  'Small': .9,
  'Standard': 1.0,
  'Large': 1.15,
  'Extra large': 1.3,
};

String savedFontFamily(String? value) =>
    studyFontFamilies.contains(value) ? value! : studyFontFamilies.first;
String savedTextSize(String? value) =>
    studyTextSizes.containsKey(value) ? value! : 'Standard';
double studyTextScale(String? size) => studyTextSizes[savedTextSize(size)]!;
