import 'dart:convert';

import 'package:askagain/services/generation_draft.dart';
import 'package:askagain/services/generation_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repairs the unescaped mathematical notation shown in the error', () {
    const raw =
        r'[{"prompt":"Describe the training set.","answer":"Set: $\{(x^{(i)}, y^{(i)}); i = 1, \ldots, m\}$","page":12,"evidence":"training set"}]';
    final parsed = parseGenerationResponse(raw);
    expect(
      parsed.single['answer'],
      r'Set: $\{(x^{(i)}, y^{(i)}); i = 1, \ldots, m\}$',
    );
    final question = buildGeneratedQuestion(
      parsed.single,
      {12: 'training set'},
      {},
      {'subject': 'maths'},
      'notes-1',
      0,
    );
    expect(question?['page'], 12);
    expect(question?['approved'], false);
  });

  test('valid JSON retains backslashes, quotes, newlines and Unicode', () {
    final expected = [
      {'answer': '• "First"\n• α = 2\tunits ${r'\frac{1}{2} \theta \\server'}'},
    ];
    expect(parseGenerationResponse(jsonEncode(expected)), expected);
    expect(
      parseGenerationResponse(r'[{"answer":"\u03b1"}]').single['answer'],
      'α',
    );
  });

  test(
    'repair preserves valid escapes and escaped quotes in the same string',
    () {
      final parsed = parseGenerationResponse(
        r'[{"answer":"\"Set\": \{x\}\nNext: \\theta and \u03b1"}]',
      );
      expect(
        parsed.single['answer'],
        '"Set": ${r'\{x\}'}\nNext: ${r'\theta'} and α',
      );
    },
  );

  test(
    'literal invalid Unicode command is preserved rather than discarded',
    () {
      expect(
        parseGenerationResponse(r'[{"answer":"\underbrace{x}"}]')
            .single['answer'],
        r'\underbrace{x}',
      );
    },
  );

  test('accepts a complete fenced JSON response', () {
    expect(parseGenerationResponse('```json\n[{"page":12}]\n```'), [
      {'page': 12},
    ]);
  });

  test('rejects truncated data, wrong shapes and empty responses safely', () {
    for (final raw in <String?>[
      null,
      '',
      '```',
      '```json',
      '[{"answer":"unfinished',
      '[{"answer":"ok"}',
      '{"answer":"ok"}',
      '[1]',
      r'[{"answer":"ok"},\oops]',
    ]) {
      expect(
        () => parseGenerationResponse(raw),
        throwsA(isA<GenerationResponseException>()),
        reason: '$raw',
      );
    }
  });

  test('repaired response still rejects fabricated source evidence', () {
    final parsed = parseGenerationResponse(
      r'[{"prompt":"Set?","answer":"\{x\}","page":12,"evidence":"invented"}]',
    );
    expect(
      buildGeneratedQuestion(
        parsed.single,
        {12: 'training set'},
        {},
        {'subject': 'maths'},
        'notes-1',
        0,
      ),
      isNull,
    );
  });
}
