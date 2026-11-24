import 'dart:async';

class GenerationCancelled implements Exception {
  const GenerationCancelled();
}

/// Stops waiting for an active model call and prevents subsequent batches.
/// The provider may still finish a request that was already sent.
class GenerationCancellation {
  final _signal = Completer<void>();

  bool get isCancelled => _signal.isCompleted;

  void cancel() {
    if (!_signal.isCompleted) _signal.complete();
  }

  void throwIfCancelled() {
    if (isCancelled) throw const GenerationCancelled();
  }

  Future<T> untilCancelled<T>(Future<T> operation) {
    throwIfCancelled();
    return Future.any<T>([
      operation,
      _signal.future.then<T>((_) => throw const GenerationCancelled()),
    ]);
  }
}
