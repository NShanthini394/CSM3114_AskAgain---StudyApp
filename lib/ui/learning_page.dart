import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../data/notebook.dart';
import '../data/study_content.dart';
import '../data/practice_session.dart';
import '../services/reminders.dart';
import 'common.dart';
import '../data/subject_styles.dart';
import 'app_palette.dart';

class LearningPage extends StatefulWidget {
  const LearningPage({super.key, this.subject, this.chapter, this.questionIds})
    : assert(subject != null || questionIds != null);
  final String? subject;
  final String? chapter;
  final Set<String>? questionIds;
  @override
  State<LearningPage> createState() => _LearningState();
}

class _LearningState extends State<LearningPage>
    with SingleTickerProviderStateMixin {
  late final cards = scopedQuestions(
    context.book.questions,
    widget.subject,
    widget.chapter,
    questionIds: widget.questionIds,
  );
  late final flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  final session = newId(), ratings = [0, 0, 0];
  int completed = 0;
  bool saving = false;
  String error = '';
  @override
  void dispose() {
    flip.dispose();
    super.dispose();
  }

  Future<void> remember(int choice) async {
    if (saving || flip.isAnimating || flip.value < 1) return;
    setState(() {
      saving = true;
      error = '';
    });
    try {
      await context.book.rate(
        cards[completed],
        recallRating(choice),
        '',
        'Self-rated recall',
        session: session,
        activity: 'recall',
      );
      if (!mounted) return;
      setState(() {
        ratings[choice]++;
        completed++;
        flip.reset();
      });
      // Notification failures must not cause a second write of the same review.
      try {
        await Reminders.refresh(context.book);
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void showSource(String label, String excerpt) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * .5,
                ),
                child: SingleChildScrollView(child: SelectableText(excerpt)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget side(bool back, bool compact) {
    final q = cards[completed];
    final evidence = q['evidence'];
    final document = context.book.records[q['document']];
    final isPdf =
        document?['sourceType'] == 'pdf' ||
        (document?['sourceType'] == null &&
            (document?['name']?.toString().toLowerCase().endsWith('.pdf') ??
                false));
    final sourceLabel = isPdf && q['page'] is int
        ? 'Source: PDF page ${q['page']}'
        : 'Source: Pasted notes';
    final content =
        (back ? q['answer'] : q['studyPrompt'] ?? q['prompt']) as String;
    final centred =
        content.length <= 180 &&
        !content.contains('\n') &&
        !(back && q['mode'] == 'Programming');
    final text = SelectableText(
      content,
      textAlign: centred ? TextAlign.center : TextAlign.start,
      style: back
          ? Theme.of(context).textTheme.titleLarge
          : Theme.of(context).textTheme.headlineSmall,
    );
    final controls = back
        ? Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (final item in [
                'Fully remembered',
                'Partially remembered',
                "Didn't remember",
              ].indexed)
                OutlinedButton(
                  onPressed: saving || flip.isAnimating
                      ? null
                      : () => remember(item.$1),
                  child: Text(item.$2),
                ),
            ],
          )
        : FilledButton(
            onPressed: saving || flip.isAnimating ? null : () => flip.forward(),
            child: const Text('Show answer'),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (compact)
          text
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, size) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: size.maxHeight),
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(width: double.infinity, child: text),
                  ),
                ),
              ),
            ),
          ),
        if (back && evidence is String && evidence.trim().isNotEmpty)
          TextButton.icon(
            onPressed: () => showSource(sourceLabel, evidence),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(sourceLabel),
          ),
        const SizedBox(height: 20),
        controls,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final finished = completed >= cards.length;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Learn & Recall')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: recallCompletion(completed, cards.length),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('$completed/${cards.length} reviewed'),
                  ],
                ),
                const SizedBox(height: 20),
                if (error.isNotEmpty)
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Expanded(
                  child: finished
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cards.isEmpty
                                    ? 'No Questions to Learn'
                                    : 'Session Complete',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              if (cards.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  '${ratings[0]} fully remembered\n${ratings[1]} partially remembered\n${ratings[2]} not remembered',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        )
                      : AnimatedBuilder(
                          animation: flip,
                          builder: (context, child) {
                            final back = flip.value >= .5;
                            final angle = flip.value * math.pi;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, .001)
                                ..rotateY(angle),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..rotateY(back ? math.pi : 0),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  color:
                                      AppPalette(
                                        Theme.of(context).brightness ==
                                            Brightness.dark,
                                      ).folder(
                                        subjectColour(
                                          context
                                              .book
                                              .records[cards[completed]['subject']],
                                        ),
                                      ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: LayoutBuilder(
                                      builder: (context, size) {
                                        if (size.maxHeight < 360) {
                                          return SingleChildScrollView(
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minHeight: size.maxHeight,
                                              ),
                                              child: side(back, true),
                                            ),
                                          );
                                        }
                                        return side(back, false);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
