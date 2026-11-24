import 'package:flutter_test/flutter_test.dart';
import 'package:askagain/services/generation_draft.dart';

void main() {
  const page = 'Photosynthesis uses light energy to make glucose.';
  final settings = <String, dynamic>{'subject': 'biology', 'chapter': 'plants'};
  final draft = <String, dynamic>{
    'prompt': 'What does photosynthesis use?',
    'answer': '• Light energy.\n• Carbon dioxide and water.',
    'page': 12,
    'evidence': 'uses light energy to make glucose',
    'responseFormat': 'Written answer',
    'type': 'Definition',
  };

  test('accepts a sourced draft with an inferred question type', () {
    final question = buildGeneratedQuestion(
      draft,
      {12: page},
      {},
      settings,
      'notes-1',
      0,
    );
    expect(question?['type'], 'Definition');
    expect(question?['page'], 12);
    expect(question?['approved'], false);
  });

  test('rejects unsupported and duplicate drafts', () {
    expect(
      buildGeneratedQuestion(
        {...draft, 'evidence': 'a passage absent from the page'},
        {12: page},
        {},
        settings,
        'notes-1',
        0,
      ),
      isNull,
    );
    expect(
      buildGeneratedQuestion(
        draft,
        {12: page},
        {normalizedQuestion(draft['prompt'] as String)},
        settings,
        'notes-1',
        0,
      ),
      isNull,
    );
  });
}
