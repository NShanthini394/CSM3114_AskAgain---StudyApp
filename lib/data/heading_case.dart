const _minorWords = {
  'a',
  'an',
  'and',
  'as',
  'at',
  'but',
  'by',
  'for',
  'from',
  'in',
  'into',
  'nor',
  'of',
  'on',
  'or',
  'the',
  'to',
  'up',
  'via',
  'with',
};

/// For app-owned English headings only, never educational content.
String headingCase(String text) {
  final words = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)*")
      .allMatches(text)
      .toList();
  var index = 0;
  return text.replaceAllMapped(RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)*"), (match) {
    final word = match.group(0)!;
    final at = index++;
    if (at > 0 &&
        at < words.length - 1 &&
        _minorWords.contains(word.toLowerCase())) {
      return word.toLowerCase();
    }
    // Keep acronyms and brand names such as PDF, AI and AskAgain.
    if (word == word.toUpperCase() ||
        word.substring(1).contains(RegExp('[A-Z]'))) {
      return word;
    }
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  });
}
