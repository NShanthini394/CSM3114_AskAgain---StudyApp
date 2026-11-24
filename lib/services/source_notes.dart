import 'dart:convert';

import '../data/study_rules.dart';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class Notes {
  Notes(this.name, this.pages, this.fingerprint, {this.isPdf = false}) {
    if (pages.isEmpty) {
      throw const FormatException(
        'No readable text found. Paste the text from your notes.',
      );
    }
    if (pages.length > 80) {
      throw const FormatException(
        'Choose a document with at most 80 meaningful pages.',
      );
    }
  }
  final String name, fingerprint;
  final Map<int, String> pages;
  final bool isPdf;
  static String digest(String text) =>
      sha256.convert(utf8.encode(text)).toString();
  factory Notes.text(String name, String raw) {
    final clean = raw.trim();
    if (clean.length > 160000) {
      throw const FormatException('Paste up to 160,000 characters.');
    }
    return Notes(name, {
      if (clean.isNotEmpty) 1: clean,
    }, digest(clean.replaceAll(RegExp(r'\s+'), ' ')));
  }
  static Future<Notes?> pdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null) return null;
    if ((await file.length() ?? 0) > 24 * 1024 * 1024) {
      throw const FormatException('Choose a PDF smaller than 24 MB.');
    }
    final extracted = await const MethodChannel('askagain/pdf')
        .invokeListMethod<String>('pages', await file.readAsBytes());
    final pages = <int, String>{};
    for (int i = 0; i < (extracted?.length ?? 0); i++) {
      final text = extracted![i].trim();
      if (text.length >= 30 &&
          !RegExp(
            r'^(table of contents|references|bibliography)\s*[\r\n]',
            caseSensitive: false,
          ).hasMatch(text)) {
        pages[i + 1] = text;
      }
    }
    return Notes(
      file.name,
      pages,
      digest(pages.values.join(' ').replaceAll(RegExp(r'\s+'), ' ')),
      isPdf: true,
    );
  }

  String get mode {
    final text = pages.values.join(' ');
    final code = RegExp(
      r'\b(function|class|return|compile|for loop)\b',
      caseSensitive: false,
    ).hasMatch(text);
    final stats = RegExp(
      r'\b(variance|standard deviation|p-value|regression)\b',
      caseSensitive: false,
    ).hasMatch(text);
    final math = RegExp(
      r'[=√∑]|\b(calculate|equation)\b',
      caseSensitive: false,
    ).hasMatch(text);
    return code && math
        ? 'Mixed'
        : code
        ? 'Programming'
        : stats
        ? 'Statistics'
        : math
        ? 'Calculation'
        : 'Theory';
  }

  static int limit(Map<int, String> pages) => questionLimit(pages);
}
