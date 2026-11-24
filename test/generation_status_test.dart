import 'package:askagain/services/generation_input.dart';
import 'package:askagain/services/generation_job.dart';
import 'package:askagain/ui/generation_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const overloaded =
      'FirebaseAIException: Server Error [500]: '
      '{"error":{"code":500,"message":"This model is currently experiencing '
      'high demand. Please try again later.","status":"INTERNAL"}}';

  test(
    'provider overload is retryable but quota and other 500 errors are not',
    () {
      expect(isTemporaryGenerationFailure(overloaded), isTrue);
      expect(
        isTemporaryGenerationFailure('Server Error [500]: broken config'),
        isFalse,
      );
      expect(
        isTemporaryGenerationFailure('Server Error [429]: quota exceeded'),
        isFalse,
      );
      final message = generationFailureMessage(overloaded);
      expect(message, contains('server-capacity'));
      expect(message, isNot(contains('FirebaseAIException')));
      expect(message, isNot(contains('"error"')));
    },
  );

  final job = GenerationJob.instance;
  setUp(() {
    job.visible = true;
    job.running = false;
    job.cancelling = false;
    job.resultId = null;
    job.error = null;
    job.retryAfter = null;
    job.stage = 'Writing batch 1 of 1…';
    job.totalBatches = 1;
    job.completedBatches = 0;
  });
  tearDown(() {
    job.running = false;
    job.cancelling = false;
    job.error = null;
    job.resultId = null;
    job.retryAfter = null;
    job.dismiss();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GenerationStatusAction())),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'running dialog has Cancel left of Close and Close preserves work',
    (tester) async {
      job.running = true;
      await open(tester);
      expect(find.text('Dismiss'), findsNothing);
      expect(
        tester.getCenter(find.text('Cancel')).dx,
        lessThan(tester.getCenter(find.text('Close')).dx),
      );
      await tester.tap(find.text('Close'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(job.running, isTrue);
      expect(job.visible, isTrue);
    },
  );

  testWidgets(
    'paused dialog has Cancel, Close, Retry and Cancel ends the job',
    (tester) async {
      job.error = generationFailureMessage(overloaded);
      job.stage = 'Generation paused';
      await open(tester);
      expect(find.text('Dismiss'), findsNothing);
      expect(
        tester.getCenter(find.text('Cancel')).dx,
        lessThan(tester.getCenter(find.text('Close')).dx),
      );
      expect(
        tester.getCenter(find.text('Close')).dx,
        lessThan(tester.getCenter(find.text('Retry')).dx),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(job.visible, isFalse);
      expect(job.stage, 'Generation cancelled');
      expect(job.error, isNull);
    },
  );

  testWidgets('saving cannot be cancelled and completion offers review', (
    tester,
  ) async {
    job.running = true;
    job.stage = 'Saving question set…';
    await open(tester);
    expect(find.text('Cancel'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(milliseconds: 300));
    job.running = false;
    job.resultId = 'notes-demo';
    await open(tester);
    expect(find.text('Review Questions'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });
}
