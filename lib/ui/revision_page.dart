import '../data/study_rules.dart';

import 'package:material_ui/material_ui.dart';

import '../data/notebook.dart';
import '../services/reminders.dart';
import 'common.dart';
import '../data/answer_formats.dart';
import 'structured_answer.dart';
import '../services/answer_feedback.dart';
import '../data/practice_session.dart';
import '../data/heading_case.dart';

class RevisionPage extends StatefulWidget {
  const RevisionPage({
    super.key,
    this.subject,
    this.chapter,
    this.initialQuestions,
    this.sessionNotice,
  });
  final String? subject;
  final String? chapter;
  final List<StudyRecord>? initialQuestions;
  final String? sessionNotice;
  @override
  State<RevisionPage> createState() => _Session();
}

class _Session extends State<RevisionPage> {
  late List<StudyRecord> queue;
  int at = 0;
  bool revealed = false, saving = false;
  String mistake = '', result = '', filter = 'Daily';
  String structuredFeedback = '';
  bool structuredComplete = false;
  final sessionId = newId();
  bool checking = false;
  String aiFeedback = '';
  final includedPoints = <int>{};
  final answer = TextEditingController(),
      unit = TextEditingController(),
      working = TextEditingController();
  @override
  void initState() {
    super.initState();
    filter = widget.subject == null ? 'Daily' : 'Subject';
    load();
  }

  void load() {
    final b = context.book;
    queue =
        (widget.initialQuestions ?? (filter == 'Daily' ? b.due : b.questions))
            .where(
              (q) =>
                  (widget.subject == null || q['subject'] == widget.subject) &&
                  (widget.chapter == null ||
                      (q['chapter'] ?? '') == widget.chapter) &&
                  (filter != 'Weak' || (q['rating'] ?? 4) < 2),
            )
            .toList();
    final exams =
        b.rows('exam').where((e) => e['date'].compareTo(today()) >= 0).toList()
          ..sort((a, b) => a['date'].compareTo(b['date']));
    int priority(StudyRecord q) {
      final n = exams.indexWhere((e) => e['subject'] == q['subject']);
      return n < 0 ? 99999 : n;
    }

    if (widget.initialQuestions == null) queue = shuffledContent(queue);
    if (widget.initialQuestions == null && widget.subject == null) {
      queue.sort((a, b) {
        final rank = priority(a).compareTo(priority(b));
        return rank != 0
            ? rank
            : (a['rating'] as int? ?? -1).compareTo(b['rating'] ?? -1);
      });
    }
    if (filter == 'Quick') queue = queue.take(5).toList();
    at = 0;
  }

  @override
  void dispose() {
    answer.dispose();
    unit.dispose();
    working.dispose();
    super.dispose();
  }

  void reveal(StudyRecord q) {
    final target = double.tryParse(q['numeric']?.toString() ?? '');
    result = '';
    if (['Fill in the blanks', 'Matching'].contains(responseFormat(q))) {
      result = structuredFeedback;
    }
    if (target != null && responseFormat(q) == 'Numerical answer') {
      final tol = double.tryParse(q['tolerance']?.toString() ?? '') ?? 0;
      final correct = matchesNumericAnswer(
        answer.text,
        target,
        tol,
        unit.text,
        q['unit'] ?? '',
      );
      result = correct
          ? 'Value and unit match.'
          : 'Compare your value, rounding and unit.';
    }
    setState(() => revealed = true);
  }

  Future<void> advance(StudyRecord q, int rating) async {
    setState(() => saving = true);
    try {
      await context.book.rate(
        q,
        rating,
        mistake,
        answer.text,
        session: sessionId,
      );
      if (!mounted) return;
      at++;
      answer.clear();
      unit.clear();
      working.clear();
      mistake = '';
      revealed = false;
      structuredFeedback = '';
      structuredComplete = false;
      aiFeedback = '';
      includedPoints.clear();
      await Reminders.refresh(context.book);
    } catch (e) {
      if (mounted) context.message(e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = at < queue.length ? queue[at] : null;
    final mode = q?['mode'],
        math =
            mode == 'Statistics' ||
            mode == 'Calculation' ||
            q != null && responseFormat(q) == 'Numerical answer',
        code = q != null && responseFormat(q) == 'Code answer';
    final structured =
        q != null &&
        ['Fill in the blanks', 'Matching'].contains(responseFormat(q));
    return Scaffold(
      appBar: AppBar(title: const Text('Revision')),
      body: PageBody([
        if (widget.sessionNotice != null) Text(widget.sessionNotice!),
        if (at == 0 && !revealed && widget.initialQuestions == null)
          Wrap(
            spacing: 6,
            children: [
              for (final f in {
                widget.subject == null ? 'Daily' : 'Subject',
                'Weak',
                'Quick',
              })
                ChoiceChip(
                  label: Text(f),
                  selected: filter == f,
                  onSelected: (_) => setState(() {
                    filter = f;
                    load();
                    answer.clear();
                    working.clear();
                    unit.clear();
                    structuredComplete = false;
                    structuredFeedback = '';
                  }),
                ),
            ],
          ),
        if (q == null) ...[
          TitleLine(
            at == 0 ? 'No Questions in This Queue' : 'Session Complete',
          ),
          Text(
            at == 0
                ? 'Finalise a question set or select another revision mode.'
                : 'You reviewed $at questions. Your next reviews are scheduled.',
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ] else ...[
          Text('Question ${at + 1} of ${queue.length} • ${responseFormat(q)}'),
          LinearProgressIndicator(value: at / queue.length),
          TitleLine(q['prompt']),
          if (math && !revealed && !structured) ...[
            const Text('Solve on paper, or write your steps here.'),
            TextField(
              controller: working,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Working (optional)',
              ),
            ),
            Wrap(
              spacing: 4,
              children: [
                for (final symbol in [
                  '√',
                  '²',
                  'π',
                  '×',
                  '÷',
                  '±',
                  '^',
                  '/',
                  '=',
                  '≠',
                  '≤',
                  '≥',
                  '(',
                  ')',
                ])
                  ActionChip(
                    label: Text(symbol),
                    onPressed: () {
                      final pos = working.selection.isValid
                          ? working.selection.start
                          : working.text.length;
                      working.value = TextEditingValue(
                        text: working.text.replaceRange(pos, pos, symbol),
                        selection: TextSelection.collapsed(
                          offset: pos + symbol.length,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
          if (structured)
            StructuredAnswer(
              key: ValueKey('${q['id']}-$filter'),
              question: q,
              revealed: revealed,
              onChanged: (response, feedback, complete) {
                answer.text = response;
                structuredFeedback = feedback;
                structuredComplete = complete;
              },
            ),
          if (!structured)
            TextField(
              controller: answer,
              readOnly: revealed,
              style: code ? const TextStyle(fontFamily: 'monospace') : null,
              maxLines: math && q['numeric'] != null ? 1 : 5,
              keyboardType: math && q['numeric'] != null
                  ? const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    )
                  : TextInputType.multiline,
              decoration: InputDecoration(
                labelText: code
                    ? 'Your code'
                    : math
                    ? 'Final answer or interpretation'
                    : 'Your answer',
              ),
            ),
          if (!structured && math && (q['unit'] ?? '') != '')
            DropdownButtonFormField<String>(
              key: ValueKey('unit-$at-$filter'),
              items: [
                for (final u in ({
                  'm',
                  'cm',
                  'cm²',
                  's',
                  'kg',
                  '%',
                  q['unit'] as String,
                }.toList()..sort()))
                  DropdownMenuItem(value: u, child: Text(u)),
              ],
              onChanged: revealed ? null : (s) => unit.text = s ?? '',
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
          if (!revealed) ...[
            FilledButton(
              onPressed: () {
                if (structured
                    ? !structuredComplete
                    : answer.text.trim().isEmpty) {
                  context.message(
                    'Enter your answer or choose “I can’t recall”.',
                  );
                  return;
                }
                reveal(q);
              },
              child: const Text('Submit answer'),
            ),
            TextButton(
              onPressed: () => reveal(q),
              child: const Text('I can’t recall'),
            ),
          ] else ...[
            const TitleLine('Expected Answer'),
            SelectableText(
              q['answer'],
              style: code ? const TextStyle(fontFamily: 'monospace') : null,
            ),
            if (result.isNotEmpty) Text(result),
            if (!structured && !math && !code) ...[
              ExpansionTile(
                title: const Text('Answer Checkpoints'),
                subtitle: const Text('Tick the points your answer included.'),
                children: [
                  for (final point
                      in (q['answer'] as String)
                          .split(RegExp(r'\n+|[.!?]\s+'))
                          .where((s) => s.trim().isNotEmpty)
                          .take(8)
                          .indexed)
                    CheckboxListTile(
                      value: includedPoints.contains(point.$1),
                      title: Text(point.$2.trim()),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          includedPoints.add(point.$1);
                        } else {
                          includedPoints.remove(point.$1);
                        }
                      }),
                    ),
                ],
              ),
              OutlinedButton(
                onPressed: checking
                    ? null
                    : () async {
                        if (answer.text.trim().isEmpty) {
                          context.message(
                            'Write an answer before requesting feedback.',
                          );
                          return;
                        }
                        if (!context.book.cloud) {
                          context.message(
                            'Connect Firebase to use optional AI feedback. You can compare with the solution now.',
                          );
                          return;
                        }
                        if (!await confirm(
                              context,
                              'Check your answer?',
                              'Send your answer and the saved solution to Gemini for feedback? This uses an additional AI request.',
                            ) ||
                            !mounted) {
                          return;
                        }
                        setState(() => checking = true);
                        try {
                          final text = await AnswerFeedback.check(
                            q,
                            answer.text,
                          );
                          if (mounted) setState(() => aiFeedback = text);
                        } catch (e) {
                          if (context.mounted) context.message(e);
                        } finally {
                          if (mounted) setState(() => checking = false);
                        }
                      },
                child: Text(checking ? 'Checking…' : 'Check my answer with AI'),
              ),
              if (aiFeedback.isNotEmpty) Text(aiFeedback),
            ],
            if (q['evidence'] != null)
              ExpansionTile(
                title: Text('Source • Page ${q['page']}'),
                children: [Text(q['evidence'])],
              ),
            DropdownButtonFormField<String>(
              key: ValueKey(at),
              decoration: const InputDecoration(
                labelText: 'What Was Difficult? (Optional)',
              ),
              items: [
                for (final m in {
                  'Forgot',
                  'Confused concepts',
                  if (math) ...[
                    'Wrong formula',
                    'Calculation error',
                    'Incorrect unit',
                    'Wrong interpretation',
                  ],
                  if (code) ...[
                    'Syntax error',
                    'Logical error',
                    'Incorrect output',
                  ],
                })
                  DropdownMenuItem(value: m, child: Text(headingCase(m))),
              ],
              onChanged: (v) => mistake = v ?? '',
            ),
            const Text('How well did you recall it?'),
            Wrap(
              spacing: 8,
              children: [
                for (int i = 0; i < ratings.length; i++)
                  OutlinedButton(
                    onPressed: saving || checking ? null : () => advance(q, i),
                    child: Text(ratings[i]),
                  ),
              ],
            ),
          ],
        ],
      ]),
    );
  }
}
