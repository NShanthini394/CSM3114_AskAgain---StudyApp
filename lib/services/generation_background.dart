import 'package:flutter_background/flutter_background.dart';

/// Keeps the active Flutter generation request running while another app opens.
/// The Android notification remains visible until the request finishes.
class GenerationBackground {
  static Future<void> start() async {
    final ready = await FlutterBackground.initialize(
      androidConfig: const FlutterBackgroundAndroidConfig(
        notificationTitle: 'AskAgain is creating questions',
        notificationText:
            'You can use other apps while your notes are processed.',
        shouldRequestBatteryOptimizationsOff: false,
        enableWifiLock: true,
      ),
    );
    if (!ready || !await FlutterBackground.enableBackgroundExecution()) {
      throw StateError(
        'Background generation could not start. Allow AskAgain notifications and try again.',
      );
    }
  }

  static Future<void> stop() async {
    if (FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }
}
