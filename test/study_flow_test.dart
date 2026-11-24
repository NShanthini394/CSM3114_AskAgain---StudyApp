import 'package:askagain/data/notebook.dart';
import 'package:askagain/services/source_notes.dart';
import 'package:askagain/ui/revision_page.dart';
import 'package:askagain/ui/home_page.dart';
import 'package:askagain/ui/profile_page.dart';
import 'package:askagain/main.dart' show AskAgain;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('askagain/config'),
          (call) async => false,
        );
  });
  testWidgets('Home revision asks for a mode before showing due questions', (
    tester,
  ) async {
    final book = await Notebook.open();
    await book.startGuest();
    await book.change([
      {'id': 's', 'kind': 'subject', 'name': 'Biology'},
      {
        'id': 'now',
        'kind': 'question',
        'approved': true,
        'subject': 's',
        'due': today(),
        'prompt': 'A due question',
        'answer': 'A saved answer.',
      },
      {
        'id': 'later',
        'kind': 'question',
        'approved': true,
        'subject': 's',
        'due': '2999-01-01',
        'prompt': 'A future question',
        'answer': 'Another saved answer.',
      },
    ], []);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: book,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.ensureVisible(find.text('Start Revision'));
    await tester.tap(find.text('Start Revision'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Revision Mode'), findsOneWidget);
    expect(find.text('Fill in the blanks'), findsOneWidget);
    expect(find.text('Matching'), findsOneWidget);
    expect(find.text('A due question'), findsNothing);
    await tester.tap(find.text('Written / problem solving'));
    await tester.pumpAndSettle();
    expect(find.text('A due question'), findsOneWidget);
    expect(find.text('A future question'), findsNothing);
  });
  testWidgets(
    'Font licences are accessible through About rather than a settings shortcut',
    (tester) async {
      final book = await Notebook.open();
      await book.startGuest();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: book,
          child: const MaterialApp(home: ProfilePage()),
        ),
      );
      expect(find.text('Open-source licences'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('About AskAgain'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('About AskAgain'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Third-Party Packages & Licenses'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Third-Party Packages & Licenses'), findsOneWidget);
    },
  );
  testWidgets('First-use tutorial can be skipped and replayed', (tester) async {
    final book = await Notebook.open();
    await book.startGuest();
    await book.finishProfile('Learner', 'Undergraduate');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: book, child: const AskAgain()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Organize Your Subjects'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(book.tutorialComplete, isTrue);
    expect(find.text('Your Subjects'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile and settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Replay Tutorial'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Replay Tutorial'));
    await tester.pumpAndSettle();
    expect(find.text('Organize Your Subjects'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Profile and Settings'), findsOneWidget);
  });
  test(
    'Only approved questions become due, and a review survives reopening',
    () async {
      final b = await Notebook.open();
      await b.startGuest();
      await b.change([
        {
          'id': 'q',
          'kind': 'question',
          'approved': true,
          'due': today(),
          'subject': 's',
          'prompt': 'Define entropy.',
          'answer': 'A measure of uncertainty.',
        },
        {'id': 'draft', 'kind': 'question', 'approved': false},
      ], []);
      expect(b.due.map((q) => q['id']), ['q']);
      await b.rate(b.due.single, 0, 'Forgot', '');
      final saved = await Notebook.open();
      expect(saved.due, isEmpty);
      expect(saved.questions.single['interval'], 1);
      expect(saved.rows('attempt').single['mistake'], 'Forgot');
    },
  );
  test('Counts depend on content and are capped; renamed sources share an identity', () {
    expect(
      Notes.text('week one', 'A  short note').fingerprint,
      Notes.text('another name', 'A short note').fingerprint,
    );
    expect(Notes.limit({for (int i = 1; i <= 80; i++) i: 'X' * 500}), 100);
    expect(Notes.limit({1: 'Short slide'}), 1);
    expect(
      () => Notes('oversized', {for (int i = 1; i <= 81; i++) i: 'A'}, 'id'),
      throwsFormatException,
    );
  });
  testWidgets(
    'Programming revision hides the model solution until submission',
    (tester) async {
      final b = await Notebook.open();
      await b.startGuest();
      await b.save({
        'id': 'code',
        'kind': 'question',
        'approved': true,
        'subject': 'CS',
        'mode': 'Programming',
        'prompt': 'Write a Dart identity function.',
        'answer': 'int identity(int x) => x;',
      });
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: b,
          child: const MaterialApp(home: RevisionPage()),
        ),
      );
      expect(find.text('int identity(int x) => x;'), findsNothing);
      await tester.enterText(
        find.byType(TextField).first,
        'int id(int x) => x;',
      );
      await tester.ensureVisible(find.text('Submit answer'));
      await tester.tap(find.text('Submit answer'));
      await tester.pumpAndSettle();
      expect(find.text('int identity(int x) => x;'), findsOneWidget);
    },
  );
}
