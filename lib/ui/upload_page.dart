import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/notebook.dart';
import '../data/study_rules.dart';
import '../services/generation_job.dart';
import '../services/generation_input.dart';
import '../services/generation.dart';
import '../services/source_notes.dart';
import 'common.dart';
import 'auth_page.dart';
import 'chapter_selector.dart';
import 'study_language_selector.dart';
import '../data/study_languages.dart';

enum NotesInput { pdf, text }

class UploadPage extends StatefulWidget {
  const UploadPage({
    super.key,
    required this.subject,
    this.chapter,
    this.input,
  });
  final String subject;
  final String? chapter;
  final NotesInput? input;
  @override
  State<UploadPage> createState() => _Upload();
}

class _Upload extends State<UploadPage> {
  final selectedFormats = <String>{'Written answer'};
  late String chapter = widget.chapter ?? '';
  Future<bool> trialAccess() async {
    if (!context.book.guest || !context.book.guestTrialUsed) return true;
    await context.open(const AuthPage(upgrade: true));
    return mounted && !context.book.guest;
  }

  Notes? notes;
  late String subject = widget.subject;
  String mode = 'Theory',
      scope = '',
      topic = '',
      text = '',
      title = '',
      message = '';
  String language = studyLanguages.first;
  int count = 1;
  bool starting = false;
  final difficulties = <String>{'Medium'};
  static const contentModes = [
    'Theory',
    'Calculation',
    'Statistics',
    'Programming',
    'Mixed',
  ];
  Map<int, String> get selected {
    final source = notes;
    if (source == null) return {};
    if (scope.trim().isEmpty) return source.pages;
    final numbers = <int>{};
    for (final part in scope.split(',')) {
      final range = part.trim().split('-');
      if (range.length > 2) return {};
      final a = int.tryParse(range.first.trim()),
          b = int.tryParse(range.last.trim());
      if (a == null ||
          b == null ||
          a < 1 ||
          b < a ||
          b > source.pages.keys.last) {
        return {};
      }
      numbers.addAll(source.pages.keys.where((p) => p >= a && p <= b));
    }
    return Map.fromEntries(
      source.pages.entries.where((p) => numbers.contains(p.key)),
    );
  }

  int get maxCount => selected.isEmpty ? 0 : Notes.limit(selected);
  void accept(Notes n) {
    setState(() {
      notes = n;
      mode = n.mode;
      scope = '';
      count = math.max(1, (maxCount * .65).round());
      message = '';
    });
  }

  Future<void> generate() async {
    if (starting) return;
    if (GenerationJob.instance.running) {
      setState(
        () => message = 'A question set is already being created. Check its progress from the top of the app.',
      );
      return;
    }
    if (!await trialAccess() || !mounted) return;
    if (selected.isEmpty || difficulties.isEmpty || selectedFormats.isEmpty) {
      setState(
        () => message = 'Choose valid pages and at least one difficulty.',
      );
      return;
    }
    if (!context.book.cloud) {
      setState(
        () => message = 'Gemini generation requires the Firebase-connected build. You can write questions and revise in the local notebook.',
      );
      return;
    }
    final pause = Generation.currentPause(context.book);
    if (pause != null) {
      setState(() => message = pause.toString());
      return;
    }
    final chosenPages = selected;
    final estimatedRequests = plannedGenerationCalls(
      chosenPages,
      count,
    );
    setState(() => starting = true);
    try {
      final usage = await context.book.collection
          .doc('usage-${today().replaceAll('-', '')}')
          .get();
      final used = usage.data()?['requests'] as int? ?? 0;
      if (!mounted) return;
      if (!withinDailyGenerationAllowance(
        usedRequests: used,
        requestedRequests: estimatedRequests,
        requestedPages: chosenPages.length,
        requestedQuestions: count,
      )) {
        setState(() {
          starting = false;
          message =
              'This set needs about $estimatedRequests AI requests. Your AskAgain generation allowance has ${math.max(0, dailyGenerationRequestAllowance - used)} left today. Select fewer pages or questions, or try tomorrow.';
        });
        return;
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          starting = false;
          message = generationFailureMessage(error);
        });
      }
      return;
    }
    final accepted = await confirm(
      context,
      'Generate one question set?',
      'Send the selected notes to Gemini for up to $count questions? Estimated $estimatedRequests AI requests, one per batch. Use material you may share. You can edit or add questions after generation. Each document gets one completed set.',
    );
    if (!mounted) return;
    if (!accepted) {
      setState(() => starting = false);
      return;
    }
    final book = context.book;
    final acceptedJob = GenerationJob.instance.start(
      book,
      notes!,
      chosenPages,
      count,
      {
        'subject': subject,
        'chapter': chapter,
        'mode': mode,
        'language': language,
        'topic': topic.trim(),
        'level': book.profile['level'],
        'difficulties': difficulties.toList(),
        'responseFormats': selectedFormats.toList(),
      },
    );
    if (acceptedJob && mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (mounted) {
      setState(() {
        starting = false;
        message = 'Another question set is already in progress.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.book;
    return Scaffold(
      appBar: AppBar(title: const Text('Create from Notes')),
      body: PageBody([
        DropdownButtonFormField(
          initialValue: subject,
          decoration: const InputDecoration(labelText: 'Subject'),
          items: [
            for (final s in b.rows('subject'))
              DropdownMenuItem(
                value: s['id'] as String,
                child: Text(s['name']),
              ),
          ],
          onChanged: (v) => setState(() {
            subject = v!;
            chapter = '';
          }),
        ),
        ChapterSelector(
          subject: subject,
          value: chapter,
          onChanged: (v) => setState(() => chapter = v),
        ),
        if (b.guest)
          Text(
            'Guest trial: ${b.guestTrialUsed ? 1 : 0} of 1 question set used',
          ),
        if (b.cloud)
          StreamBuilder<DocumentSnapshot<StudyRecord>>(
            stream: b.collection
                .doc('usage-${today().replaceAll('-', '')}')
                .snapshots(),
            builder: (context, snapshot) {
              final used = snapshot.data?.data()?['requests'] as int? ?? 0;
              return Text(
                'AskAgain generation calls today (this account): $used/$dailyGenerationRequestAllowance. Google’s free quota is shared across the project, so its remaining balance may be lower.',
              );
            },
          ),
        if (b.guest && b.guestTrialUsed)
          FilledButton(
            onPressed: () => context.open(const AuthPage(upgrade: true)),
            child: const Text('Sign in to create more questions'),
          ),
        if (widget.input != NotesInput.text)
          OutlinedButton.icon(
            onPressed: () async {
              if (!await trialAccess()) return;
              try {
                final n = await Notes.pdf();
                if (n != null && mounted) accept(n);
              } catch (e) {
                if (mounted) setState(() => message = e.toString());
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Choose PDF'),
          ),
        if (widget.input != NotesInput.pdf)
          ExpansionTile(
            initiallyExpanded: widget.input == NotesInput.text,
            title: const Text('Paste Notes Instead'),
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Document Title'),
                onChanged: (v) => title = v,
              ),
              TextField(
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Notes'),
                onChanged: (v) => text = v,
              ),
              TextButton(
                onPressed: () {
                  try {
                    accept(
                      Notes.text(
                        title.trim().isEmpty ? 'Pasted notes' : title.trim(),
                        text,
                      ),
                    );
                  } catch (e) {
                    setState(() => message = e.toString());
                  }
                },
                child: const Text('Use these notes'),
              ),
            ],
          ),
        if (notes != null) ...[
          TitleLine(notes!.name),
          Text('${notes!.pages.length} readable study pages'),
          DropdownButtonFormField(
            initialValue: mode,
            key: ValueKey(notes),
            decoration: const InputDecoration(labelText: 'Content Mode'),
            items: [
              for (final m in contentModes)
                DropdownMenuItem(value: m, child: Text(m)),
            ],
            onChanged: (v) => setState(() => mode = v!),
          ),
          TextField(
            key: ValueKey(notes!.fingerprint),
            decoration: const InputDecoration(
              labelText: 'Pages (optional)',
              hintText: 'e.g. 2-6, 9',
            ),
            onChanged: (v) => setState(() {
              scope = v;
              count = maxCount == 0
                  ? 0
                  : math.min(count == 0 ? 1 : count, maxCount);
            }),
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Focus Topic (Optional)',
            ),
            onChanged: (v) => topic = v,
          ),
          if (maxCount > 0) ...[
            Text(
              'Up to $count questions • recommended ${math.max(1, (maxCount * .65).round())} • maximum $maxCount',
            ),
            if (maxCount > 1)
              Slider(
                min: 1,
                max: maxCount.toDouble(),
                divisions: maxCount - 1,
                value: count.clamp(1, maxCount).toDouble(),
                label: '$count',
                onChanged: (v) => setState(() => count = v.round()),
              ),
            Text(
              'Estimated AI requests for this set: ${plannedGenerationCalls(selected, count)} (one per batch; a temporary server error may use one extra retry). This is not a live Google quota balance. Very dense pages use excerpts from their beginning, middle and end; choose fewer pages for more complete coverage.',
            ),
          ] else
            const Text('Enter a page range containing readable notes.'),
          const TitleLine('Difficulty'),
          chips(['Easy', 'Medium', 'Hard'], difficulties),
          StudyLanguageSelector(
            value: language,
            label: 'Q&A language (optional)',
            onChanged: (v) => setState(() => language = v),
          ),
          FilledButton.icon(
            onPressed: starting ? null : generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate questions'),
          ),
        ],
        if (message.isNotEmpty)
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ]),
    );
  }

  Widget chips(List<String> values, Set<String> selected) => Wrap(
    spacing: 6,
    children: [
      for (final v in values)
        FilterChip(
          label: Text(v),
          selected: selected.contains(v),
          onSelected: (yes) => setState(() {
            if (yes) {
              selected.add(v);
            } else {
              selected.remove(v);
            }
          }),
        ),
    ],
  );
}

String generationFailureMessage(Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();
  if (lower.contains('firebase_app_check') &&
      lower.contains('too many attempts')) {
    return 'Firebase security is temporarily limiting App Check requests. '
        'Close AskAgain, wait about 5 minutes, then reopen it and try once. '
        'If this continues, verify that this phone\'s current debug token is '
        'registered in Firebase App Check.';
  }
  if (lower.contains('generation is in progress')) {
    return 'Another question generation is still running. Wait for it to '
        'finish before starting a new one.';
  }
  return raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
}
