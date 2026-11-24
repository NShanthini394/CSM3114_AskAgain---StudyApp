import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/answer_formats.dart';
import '../data/study_content.dart';

class StructuredAnswer extends StatefulWidget {
  const StructuredAnswer({
    super.key,
    required this.question,
    required this.revealed,
    required this.onChanged,
  });
  final Map<String, dynamic> question;
  final bool revealed;
  final void Function(String response, String feedback, bool complete)
  onChanged;
  @override
  State<StructuredAnswer> createState() => _StructuredState();
}

class _StructuredState extends State<StructuredAnswer> {
  late final blanks = List.generate(
    (widget.question['blanks'] as List? ?? []).length,
    (_) => TextEditingController(),
  );
  late final order = List.generate(
    (widget.question['pairs'] as List? ?? []).length,
    (i) => i,
  )..shuffle(Random());
  final selection = PairSelection();
  void changed() {
    if (responseFormat(widget.question) == 'Fill in the blanks') {
      final values = blanks.map((c) => c.text).toList();
      widget.onChanged(
        values.join('\n'),
        '${scoreBlanks(widget.question['blanks'], values)} of ${values.length} blanks correct.',
        values.every((v) => v.trim().isNotEmpty),
      );
    } else {
      final pairs = widget.question['pairs'] as List;
      widget.onChanged(
        selection.matches.entries
            .map((e) => '${pairs[e.key]['left']} = ${pairs[e.value]['right']}')
            .join('\n'),
        '${scoreMatching(pairs, selection.matches)} of ${pairs.length} matches correct.',
        selection.matches.length == pairs.length,
      );
    }
  }

  @override
  void dispose() {
    for (final c in blanks) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (responseFormat(widget.question) == 'Fill in the blanks') {
      return Column(
        children: [
          for (var i = 0; i < blanks.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: blanks[i],
                readOnly: widget.revealed,
                decoration: InputDecoration(labelText: 'Blank ${i + 1}'),
                onChanged: (_) => changed(),
              ),
            ),
        ],
      );
    }
    final pairs = widget.question['pairs'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap a question, then an answer. Tap a paired box to unpair it.',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Questions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < pairs.length; i++)
                    box(
                      pairs[i]['left'],
                      i,
                      selection.matches.containsKey(i),
                      selection.activeLeft == i,
                      () => selection.tapLeft(i),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Answers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final i in order)
                    Builder(
                      builder: (_) {
                        final owners = selection.matches.keys
                            .where((k) => selection.matches[k] == i)
                            .toList();
                        return box(
                          pairs[i]['right'],
                          owners.isEmpty ? null : owners.first,
                          owners.isNotEmpty,
                          false,
                          () => selection.tapRight(i),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget box(
    String text,
    int? pair,
    bool matched,
    bool active,
    VoidCallback tap,
  ) {
    const palette = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    final colors = Theme.of(context).colorScheme;
    final color = matched ? palette[pair! % palette.length] : colors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: active || matched,
        button: true,
        child: Material(
          color: matched
              ? color.withValues(alpha: .16)
              : active
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: matched || active ? color : colors.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.revealed
                ? null
                : () {
                    setState(tap);
                    changed();
                  },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (matched)
                    Text(
                      'Pair ${pair! + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : palette[pair % palette.length].shade800,
                      ),
                    ),
                  Text(text, softWrap: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
