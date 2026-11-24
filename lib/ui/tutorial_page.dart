import 'package:material_ui/material_ui.dart';

import 'common.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key, this.replay = false});

  final bool replay;

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialStep {
  const _TutorialStep(this.icon, this.title, this.description, this.tip);

  final IconData icon;
  final String title;
  final String description;
  final String tip;
}

class _TutorialPageState extends State<TutorialPage> {
  static const steps = [
    _TutorialStep(
      Icons.folder_outlined,
      'Organize Your Subjects',
      'Create a subject, then add chapters and questions. Your subject folders are available from Home and Subjects.',
      'Start in the Subjects tab to add your first subject.',
    ),
    _TutorialStep(
      Icons.note_add_outlined,
      'Create Study Questions',
      'Write a question yourself, upload readable PDF notes, or paste notes for AI question drafts. Review and edit every generated answer before finalizing.',
      'AI requests have daily limits. You can always add questions manually.',
    ),
    _TutorialStep(
      Icons.style_outlined,
      'Practice Your Way',
      'Use Learn & Recall flashcards or choose written answers, fill in the blanks, or matching. Open a subject to practise its questions.',
      'Check the source shown with generated questions when reviewing.',
    ),
    _TutorialStep(
      Icons.insights_outlined,
      'Review and See Progress',
      'Start today’s due revision from Home or Revision. Rate what you remember so AskAgain can schedule future reviews, then check Progress for areas needing attention.',
      'You can add exam goals and turn on daily reminders in Settings.',
    ),
  ];

  final controller = PageController();
  int index = 0;
  bool finishing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    if (finishing) return;
    setState(() => finishing = true);
    try {
      await context.book.completeTutorial();
      if (widget.replay && mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => finishing = false);
        context.message(error);
      }
    }
  }

  void next() {
    if (index == steps.length - 1) {
      finish();
    } else {
      controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Getting Started'),
        actions: [
          TextButton(
            onPressed: finishing ? null : finish,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: LinearProgressIndicator(
                value: (index + 1) / steps.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: steps.length,
                onPageChanged: (value) => setState(() => index = value),
                itemBuilder: (context, position) {
                  final step = steps[position];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            Center(
                              child: Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Icon(
                                  step.icon,
                                  size: 68,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'Step ${position + 1} of ${steps.length}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: scheme.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step.title,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              step.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(step.tip)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: index == 0 || finishing
                        ? null
                        : () => controller.previousPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                          ),
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: finishing ? null : next,
                    child: Text(
                      index == steps.length - 1 ? 'Start Learning' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
