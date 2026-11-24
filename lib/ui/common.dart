import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import '../data/heading_case.dart';

extension StudyContext on BuildContext {
  Notebook get book => read<Notebook>();
  Future<T?> open<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));
  void message(Object text) =>
      ScaffoldMessenger.of(this)
          .showSnackBar(SnackBar(content: Text(text.toString())));
}

Future<String?> input(
  BuildContext context,
  String title, [
  String initial = '',
]) async {
  var value = initial;
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(headingCase(title)),
      content: TextFormField(
        initialValue: initial,
        autofocus: true,
        maxLength: 100,
        onChanged: (s) => value = s,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (value.trim().isNotEmpty) Navigator.pop(c, value.trim());
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String details,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(headingCase(title)),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ??
    false;

class PageBody extends StatelessWidget {
  const PageBody(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
      children: [
        for (final child in children)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
      ],
    ),
  );
}

class TitleLine extends StatelessWidget {
  const TitleLine(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

const levels = [
  'Pre-university',
  'Undergraduate',
  'Postgraduate',
  'Professional',
];
const ratings = ['Forgot', 'Partially remembered', 'Understood', 'Mastered'];
