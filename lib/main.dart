import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'data/notebook.dart';
import 'services/reminders.dart';
import 'services/font_licenses.dart';
import 'ui/app_theme.dart';
import 'ui/auth_page.dart';
import 'ui/home_page.dart';
import 'ui/practice_page.dart';
import 'ui/splash_page.dart';
import 'ui/profile_setup_page.dart';
import 'ui/study_text_scaler.dart';
import 'ui/tutorial_page.dart';

final navigation = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  runApp(const StartupApp());
}

class StartupApp extends StatefulWidget {
  const StartupApp({super.key});

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late Future<Notebook> startup = openNotebook();
  bool openRevision = false;

  Future<Notebook> openNotebook() async {
    final book = await Notebook.open();
    try {
      await Reminders.init(() {
        if (!book.active) return;
        if (navigation.currentState == null) {
          openRevision = true;
        } else {
          navigation.currentState!.push(
            MaterialPageRoute(
              builder: (_) => const PracticePage(dueOnly: true),
            ),
          );
        }
      });
      if (book.active) await Reminders.refresh(book);
    } catch (error, stack) {
      // Students must retain access to their notebook if reminder setup fails.
      debugPrint('Reminder setup failed: $error\n$stack');
    }
    return book;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Notebook>(
    future: startup,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        if (openRevision) {
          openRevision = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigation.currentState?.push(
              MaterialPageRoute(
                builder: (_) => const PracticePage(dueOnly: true),
              ),
            );
          });
        }
        return ChangeNotifierProvider.value(
          value: snapshot.data!,
          child: const AskAgain(),
        );
      }
      return MaterialApp(
        title: 'AskAgain',
        debugShowCheckedModeBanner: false,
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        home: SplashPage(
          error: snapshot.hasError ? snapshot.error.toString() : null,
          onRetry: () => setState(() => startup = openNotebook()),
        ),
      );
    },
  );
}

class AskAgain extends StatelessWidget {
  const AskAgain({super.key});

  @override
  Widget build(BuildContext context) {
    final book = context.watch<Notebook>();
    return MaterialApp(
      title: 'AskAgain',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigation,
      theme: appTheme(Brightness.light, fontFamily: book.fontFamily),
      darkTheme: appTheme(Brightness.dark, fontFamily: book.fontFamily),
      themeMode: book.theme,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: StudyTextScaler(media.textScaler, book.textScale),
          ),
          child: child!,
        );
      },
      home: !book.active
          ? const AuthPage()
          : book.profileComplete
          ? book.tutorialComplete
                ? const HomePage()
                : const TutorialPage()
          : const ProfileSetupPage(),
    );
  }
}
