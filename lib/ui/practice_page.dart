import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/practice_session.dart';
import '../data/study_content.dart';
import '../data/notebook.dart';
import 'common.dart';
import 'revision_page.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({
    super.key,
    this.subject,
    this.chapter,
    this.questionIds,
    this.dueOnly = false,
  }) : assert(dueOnly || subject != null || questionIds != null);
  final String? subject;
  final String? chapter;
  final Set<String>? questionIds;
  final bool dueOnly;
  @override
  State<PracticePage> createState() => _PracticeState();
}

class _PracticeState extends State<PracticePage> {
  bool opening = false;
  String error = '';
  Future<void> start(String mode) async {
    if (opening) return;
    setState(() {
      opening = true;
      error = '';
    });
    try {
      final book = context.book;
      final source = scopedQuestions(
        widget.dueOnly ? book.due : book.questions,
        widget.subject,
        widget.chapter,
        questionIds: widget.questionIds,
      );
      final scope = widget.dueOnly
          ? 'daily'
          : widget.questionIds == null
          ? '${widget.subject}-${widget.chapter ?? 'all'}'
          : 'attention-${(widget.questionIds!.toList()..sort()).join(',')}';
      final key = 'practice-order-$scope-$mode';
      final saved = book.prefs.getString(key);
      final previous = saved == null
          ? null
          : List<String>.from(jsonDecode(saved));
      final plan = buildPracticePlan(source, mode, previous: previous);
      if (plan.questions.isEmpty) {
        setState(
          () => error = source.isEmpty
              ? widget.dueOnly
                    ? 'No questions are due for revision. You can practise any subject from its folder.'
                    : 'Add questions to this content first.'
              : plan.message,
        );
        return;
      }
      final ids = plan.questions
          .expand((q) => q['_sourceIds'] as List? ?? [q['id']])
          .map((id) => id.toString())
          .toList();
      await book.prefs.setString(key, jsonEncode(ids));
      if (!mounted) return;
      await context.open(
        RevisionPage(
          subject: widget.subject,
          chapter: widget.chapter,
          initialQuestions: plan.questions,
          sessionNotice:
              '${plan.included} of ${plan.total} questions included${mode == 'Matching' ? ' across ${plan.questions.length} rounds' : ''}.${plan.message.isEmpty ? '' : ' ${plan.message}'}',
        ),
      );
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueCount = context.watch<Notebook>().due.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dueOnly ? 'Choose Revision Mode' : 'Choose Practice',
        ),
      ),
      body: PageBody([
        if (widget.dueOnly) ...[
          TitleLine(
            '$dueCount ${dueCount == 1 ? 'Question' : 'Questions'} Due',
          ),
          Text(
            dueCount == 0
                ? 'Nothing is due right now. Open a subject folder to practise ahead.'
                : 'Choose how to practise today’s due questions.',
          ),
        ],
        for (final entry in {
          'Written / problem solving': Icons.edit_note,
          'Fill in the blanks': Icons.space_bar,
          'Matching': Icons.compare_arrows,
        }.entries)
          FilledButton.tonalIcon(
            onPressed: opening || (widget.dueOnly && dueCount == 0)
                ? null
                : () => start(entry.key),
            icon: Icon(entry.value),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(entry.key),
            ),
          ),
        if (opening) const Center(child: CircularProgressIndicator()),
        if (error.isNotEmpty)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ]),
    );
  }
}
