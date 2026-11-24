import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/notebook.dart';
import '../data/appearance.dart';
import '../services/reminders.dart';
import 'common.dart';
import 'auth_page.dart';
import 'about_page.dart';
import 'tutorial_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final b = context.watch<Notebook>(), p = b.profile;
    final min = p['minutes'] as int? ?? 1080;
    final time = TimeOfDay(hour: min ~/ 60, minute: min % 60);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile and Settings')),
      body: PageBody([
        TitleLine(p['name'] ?? 'Learner'),
        Text(
          b.guest
              ? 'Guest account • one PDF trial'
              : 'University study account',
        ),
        for (final item in {'name': 'Name'}.entries)
          ListTile(
            title: Text(item.value),
            subtitle: Text(p[item.key] ?? ''),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final v = await input(context, item.value, p[item.key] ?? '');
              if (v != null) await b.save({...p, item.key: v});
            },
          ),
        DropdownButtonFormField(
          initialValue: p['level'] ?? 'Undergraduate',
          decoration: const InputDecoration(labelText: 'Education Level'),
          items: [
            for (final l in levels) DropdownMenuItem(value: l, child: Text(l)),
          ],
          onChanged: (v) => b.save({...p, 'level': v}),
        ),
        DropdownButtonFormField(
          initialValue: b.theme,
          decoration: const InputDecoration(labelText: 'Appearance'),
          items: [
            for (final m in ThemeMode.values)
              DropdownMenuItem(
                value: m,
                child: Text(
                  {
                    'system': 'Follow device',
                    'dark': 'Dark',
                    'light': 'Light',
                  }[m.name]!,
                ),
              ),
          ],
          onChanged: (v) => b.setTheme(v!),
        ),
        DropdownButtonFormField<String>(
          key: ValueKey('font-${b.fontFamily}'),
          initialValue: b.fontFamily,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Font Type'),
          items: [
            for (final family in studyFontFamilies)
              DropdownMenuItem(
                value: family,
                child: Text(family, style: TextStyle(fontFamily: family)),
              ),
          ],
          onChanged: (v) {
            if (v != null) b.setFontFamily(v);
          },
        ),
        DropdownButtonFormField<String>(
          key: ValueKey('size-${b.textSize}'),
          initialValue: b.textSize,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Text Size',
            helperText: 'Applies throughout AskAgain and respects your phone’s text size.',
          ),
          items: [
            for (final size in studyTextSizes.keys)
              DropdownMenuItem(value: size, child: Text(size)),
          ],
          onChanged: (v) {
            if (v != null) b.setTextSize(v);
          },
        ),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleLine('Reading Preview'),
                SizedBox(height: 8),
                Text('Ask again. Recall a little more each day.\nAa Bb Cc 123'),
              ],
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Daily Revision Reminder'),
          value: p['remind'] == true,
          onChanged: (v) async {
            if (v && !await Reminders.permit()) {
              if (context.mounted) {
                context.message(
                  'Allow notifications in Android settings to receive reminders.',
                );
              }
              return;
            }
            await b.save({...p, 'remind': v});
            await Reminders.refresh(b);
          },
        ),
        if (p['remind'] == true)
          SwitchListTile(
            title: const Text('Quiet Hours'),
            subtitle: const Text(
              'Move reminders between 10 pm and 7 am to 7 am.',
            ),
            value: p['quiet'] == true,
            onChanged: (v) async {
              await b.save({...p, 'quiet': v});
              await Reminders.refresh(b);
            },
          ),
        if (p['remind'] == true)
          ListTile(
            title: const Text('Reminder Time'),
            subtitle: Text(time.format(context)),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (t != null) {
                await b.save({...p, 'minutes': t.hour * 60 + t.minute});
                await Reminders.refresh(b);
              }
            },
          ),
        TextButton.icon(
          onPressed: () => context.open(const TutorialPage(replay: true)),
          icon: const Icon(Icons.help_outline),
          label: const Text('Replay Tutorial'),
        ),
        TextButton.icon(
          onPressed: () => context.open(const AboutPage()),
          icon: const Icon(Icons.info_outline),
          label: const Text('About AskAgain'),
        ),
        if (b.guest)
          FilledButton(
            onPressed: () => context.open(const AuthPage(upgrade: true)),
            child: const Text('Sign in / Create account'),
          ),
        if (!b.guest)
          TextButton(
            onPressed: () async {
              await Reminders.plugin.cancelAll();
              await b.logout();
              if (context.mounted) {
                Navigator.popUntil(context, (r) => r.isFirst);
              }
            },
            child: const Text('Log out'),
          ),
        TextButton.icon(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          label: Text(
            b.guest ? 'Delete guest data' : 'Delete account',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onPressed: () async {
            if (!await confirm(
              context,
              b.guest ? 'Delete guest data?' : 'Delete your account?',
              'Your saved questions, notes, exams and progress will be permanently removed.',
            )) {
              return;
            }
            if (!context.mounted) return;
            String? password;
            if (b.passwordAccount) {
              password = await passwordInput(context);
              if (password == null) return;
            }
            try {
              await Reminders.plugin.cancelAll();
              await b.deleteAccount(password);
              if (context.mounted) {
                Navigator.popUntil(context, (r) => r.isFirst);
              }
            } catch (e) {
              if (context.mounted) context.message(e);
            }
          },
        ),
      ]),
    );
  }
}

Future<String?> passwordInput(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Confirm Your Password'),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Current password'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.isNotEmpty) Navigator.pop(c, controller.text);
          },
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
