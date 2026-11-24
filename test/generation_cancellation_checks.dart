import 'dart:async';
import 'dart:io';

import 'package:askagain/services/generation_cancellation.dart';

Future<void> main() async {
  void check(bool condition, String name) {
    if (!condition) throw StateError(name);
    stdout.writeln('PASS $name');
  }

  final token = GenerationCancellation();
  final pending = token.untilCancelled(Completer<String>().future);
  token.cancel();
  token.cancel();
  var stopped = false;
  try {
    await pending.timeout(const Duration(seconds: 1));
  } on GenerationCancelled {
    stopped = true;
  }
  check(stopped && token.isCancelled, 'Cancel releases an active wait');

  var nextBatchStopped = false;
  try {
    token.throwIfCancelled();
  } on GenerationCancelled {
    nextBatchStopped = true;
  }
  check(nextBatchStopped, 'Cancelled jobs cannot start another batch');

  final fresh = GenerationCancellation();
  check(
    await fresh.untilCancelled(Future.value(3)) == 3,
    'Normal work completes without cancellation',
  );
}
