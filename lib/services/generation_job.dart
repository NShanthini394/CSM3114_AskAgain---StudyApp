import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/notebook.dart';
import 'generation.dart';
import 'generation_background.dart';
import 'generation_cancellation.dart';
import 'generation_input.dart';
import 'generation_quota.dart';
import 'source_notes.dart';

/// One visible generation job for this running app. Finished batches are also
/// checkpointed by Generation, so retrying can continue after a failed batch.
class GenerationJob extends ChangeNotifier {
  GenerationJob._();
  static final instance = GenerationJob._();

  bool visible = false;
  bool running = false;
  String stage = '';
  String? resultId;
  String? error;
  int completedBatches = 0;
  int totalBatches = 0;
  bool cancelling = false;
  GenerationCancellation? _cancellation;
  Notebook? _book;
  Notes? _notes;
  Map<int, String>? _pages;
  int? _count;
  StudyRecord? _settings;

  double? get progress => totalBatches == 0
      ? null
      : (completedBatches / totalBatches).clamp(0.0, 1.0);

  bool start(
    Notebook book,
    Notes notes,
    Map<int, String> pages,
    int count,
    StudyRecord settings,
  ) {
    if (running) return false;
    _retryTimer?.cancel();
    retryAfter = null;
    _book = book;
    _notes = notes;
    _pages = Map.of(pages);
    _count = count;
    _settings = Map.of(settings);
    visible = true;
    running = true;
    cancelling = false;
    _cancellation = GenerationCancellation();
    resultId = null;
    error = null;
    stage = 'Preparing your notes…';
    completedBatches = 0;
    totalBatches = 0;
    notifyListeners();
    unawaited(_run());
    return true;
  }

  DateTime? retryAfter;
  Timer? _retryTimer;
  bool get coolingDown => retryAfter?.isAfter(DateTime.now()) ?? false;

  void retry() {
    if (coolingDown) return;
    if (running ||
        _book == null ||
        _notes == null ||
        _pages == null ||
        _count == null ||
        _settings == null) {
      return;
    }
    start(_book!, _notes!, _pages!, _count!, _settings!);
  }

  void dismiss() {
    if (running) return;
    visible = false;
    notifyListeners();
  }

  void cancel() {
    if (!running) {
      if (error == null) return;
      _retryTimer?.cancel();
      retryAfter = null;
      visible = false;
      error = null;
      stage = 'Generation cancelled';
      _notes = null;
      _pages = null;
      _settings = null;
      notifyListeners();
      return;
    }
    if (cancelling || stage == 'Saving question set…') return;
    cancelling = true;
    stage = 'Cancelling question generation…';
    _cancellation?.cancel();
    notifyListeners();
  }

  void _update(String value) {
    if (cancelling) return;
    stage = value;
    final match = RegExp(r'batch (\d+) of (\d+)').firstMatch(value);
    if (match != null) {
      totalBatches = int.parse(match.group(2)!);
      completedBatches = int.parse(match.group(1)!) - 1;
    }
    notifyListeners();
  }

  Future<void> _run() async {
    try {
      await GenerationBackground.start();
      resultId = await Generation(_book!)
          .run(_notes!, _pages!, _count!, _settings!, _update, _cancellation!);
      completedBatches = totalBatches;
      stage = 'Question set ready for review';
    } on GenerationCancelled {
      visible = false;
      stage = 'Generation cancelled';
      _notes = null;
      _pages = null;
      _settings = null;
    } catch (e) {
      error = generationFailureMessage(e);
      if (e is GenerationQuotaPause) {
        retryAfter = e.until;
        _retryTimer = Timer(
          e.until.difference(DateTime.now()),
          notifyListeners,
        );
      }
      stage = 'Generation paused';
    } finally {
      try {
        await GenerationBackground.stop();
      } catch (_) {}
      running = false;
      cancelling = false;
      _cancellation = null;
      notifyListeners();
    }
  }
}
