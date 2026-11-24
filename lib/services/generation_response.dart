import 'dart:convert';

/// A malformed response must not expose raw JSON or private notes in the UI.
class GenerationResponseException implements Exception {
  const GenerationResponseException();

  @override
  String toString() =>
      'The AI returned an incomplete or unreadable question batch. '
      'Completed batches are saved. Tap Retry to request this batch again.';
}

/// Decode complete batches, repairing only invalid escapes inside JSON strings.
/// Valid JSON is left untouched; no questions or closing brackets are invented.
List<dynamic> parseGenerationResponse(String? response) {
  var text = response?.trim() ?? '';
  if (text.length >= 10 && text.startsWith('```json') && text.endsWith('```')) {
    text = text.substring(7, text.length - 3).trim();
  } else if (text.length >= 6 &&
      text.startsWith('```') &&
      text.endsWith('```')) {
    text = text.substring(3, text.length - 3).trim();
  }
  Object? decoded;
  try {
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      decoded = jsonDecode(_repairStringEscapes(text));
    }
  } on FormatException {
    throw const GenerationResponseException();
  }
  if (decoded is! List || decoded.any((item) => item is! Map)) {
    throw const GenerationResponseException();
  }
  return decoded;
}

String _repairStringEscapes(String text) {
  final result = StringBuffer();
  var inString = false;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '"') {
      inString = !inString;
    } else if (inString && char == r'\' && i + 1 < text.length) {
      final next = text[i + 1];
      final validUnicode =
          next == 'u' &&
          i + 5 < text.length &&
          RegExp(r'^[0-9a-fA-F]{4}$').hasMatch(text.substring(i + 2, i + 6));
      if ('"\\/bfnrt'.contains(next) || validUnicode) {
        // Consume the pair so an escaped quote cannot change string state.
        result.write(char);
        result.write(next);
        i++;
        continue;
      }
      // Preserve the literal backslash in mathematical notation such as \{.
      result.write(r'\');
    }
    result.write(char);
  }
  return result.toString();
}
