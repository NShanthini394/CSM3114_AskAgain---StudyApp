import 'package:material_ui/material_ui.dart';

import 'common.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.upgrade = false});
  final bool upgrade;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool register = false, busy = false, visible = false;
  String error = '';
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> perform(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await action();
      if (widget.upgrade && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = context.book;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AskAgain'),
        actions: [
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    register = !register;
                    error = '';
                  }),
            child: Text(register ? 'Sign in' : 'Create account'),
          ),
        ],
      ),
      body: AutofillGroup(
        child: Form(
          key: form,
          child: PageBody([
            const Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: Color(0xff3657d6),
            ),
            Text(
              register ? 'Create Your Account' : 'Welcome to AskAgain',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              widget.upgrade
                  ? 'Keep your questions and progress when you sign in.'
                  : 'Turn your notes into questions and build your revision routine.',
              textAlign: TextAlign.center,
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => perform(book.googleLogin),
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continue with Google'),
            ),
            const Text('Or use your email', textAlign: TextAlign.center),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(v?.trim() ?? '')
                  ? 'Enter a valid email'
                  : null,
            ),
            TextFormField(
              controller: password,
              obscureText: !visible,
              autofillHints: [
                register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: visible ? 'Hide password' : 'Show password',
                  onPressed: () => setState(() => visible = !visible),
                  icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < 6 ? 'Use at least six characters' : null,
            ),
            if (error.isNotEmpty)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      if (form.currentState!.validate()) {
                        perform(
                          () => book.login(
                            email.text.trim(),
                            password.text,
                            register: register,
                          ),
                        );
                      }
                    },
              child: Text(
                busy
                    ? 'Please wait…'
                    : register
                    ? 'Create account'
                    : 'Sign in',
              ),
            ),
            if (!widget.upgrade) ...[
              TextButton(
                onPressed: busy ? null : () => perform(book.startGuest),
                child: const Text('Try as guest'),
              ),
              const Text(
                'Guest trial includes one PDF question set. Sign in to generate more.',
                textAlign: TextAlign.center,
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
