import 'package:material_ui/material_ui.dart';

import 'common.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});
  @override
  State<ProfileSetupPage> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetupPage> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: context.book.profile['name'] ?? '',
  );
  late String level = context.book.profile['level'] ?? 'Undergraduate';
  bool saving = false;
  String error = '';
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Set up Your Profile')),
    body: Form(
      key: form,
      child: PageBody([
        const TitleLine('How Should We Address You?'),
        TextFormField(
          controller: name,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            helperText: 'You can use your first name or a nickname.',
          ),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Enter your display name' : null,
        ),
        DropdownButtonFormField(
          initialValue: level,
          decoration: const InputDecoration(labelText: 'Education Level'),
          items: [
            for (final l in levels) DropdownMenuItem(value: l, child: Text(l)),
          ],
          onChanged: (v) => level = v!,
        ),
        if (error.isNotEmpty)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: saving
              ? null
              : () async {
                  if (!form.currentState!.validate()) return;
                  setState(() => saving = true);
                  try {
                    await context.book.finishProfile(name.text.trim(), level);
                  } catch (e) {
                    if (mounted) setState(() => error = e.toString());
                  } finally {
                    if (mounted) setState(() => saving = false);
                  }
                },
          child: Text(saving ? 'Saving…' : 'Start learning'),
        ),
      ]),
    ),
  );
}
