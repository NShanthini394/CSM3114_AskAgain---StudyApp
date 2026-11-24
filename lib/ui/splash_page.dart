import 'package:material_ui/material_ui.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.error, this.onRetry});
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: const Color(0xff3657d6),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 64,
                      color: Color(0xff9deae2),
                    ),
                    Positioned(
                      right: 24,
                      top: 19,
                      child: Icon(
                        Icons.bookmark,
                        size: 25,
                        color: Color(0xffc5192d),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AskAgain',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 32),
              if (error == null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                )
              else ...[
                Text(
                  'Unable to open your notebook',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectableText(error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
