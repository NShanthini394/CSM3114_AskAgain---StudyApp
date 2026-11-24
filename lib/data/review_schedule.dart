import 'study_rules.dart';

Map<String, dynamic> scheduledReview(
  Map<String, dynamic> source,
  int rating,
  DateTime now, {
  String activity = 'practice',
}) {
  final day = now.toLocal().toIso8601String().split('T').first;
  final previousDays = List<String>.from(source['recallSuccessDays'] ?? []);
  var effective = rating;
  var days = previousDays;
  if (rating < 2) {
    days = [];
  } else if (activity == 'recall') {
    days = {...previousDays, day}.toList()..sort();
    if (days.length >= 3 || source['rating'] == 3) effective = 3;
  }
  final interval = nextInterval(source['interval'] ?? 0, effective);
  return {
    ...source,
    'rating': effective,
    'interval': interval,
    'recallSuccessDays': days,
    'due': now
        .toLocal()
        .add(Duration(days: interval))
        .toIso8601String()
        .split('T')
        .first,
  };
}
