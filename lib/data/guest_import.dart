/// Merge new guest records without replacing the destination account's work.
List<Map<String, dynamic>> guestRecordsToImport(
  Map<String, dynamic> source,
  Map<String, dynamic> destination,
) {
  final conflictingDocuments = source.values
      .whereType<Map>()
      .where((r) => r['kind'] == 'document' && destination.containsKey(r['id']))
      .map((r) => r['id'])
      .toSet();
  final conflictingQuestions = source.values
      .whereType<Map>()
      .where(
        (r) =>
            r['kind'] == 'question' &&
            conflictingDocuments.contains(r['document']),
      )
      .map((r) => r['id'])
      .toSet();
  return source.values
      .whereType<Map>()
      .where((r) {
        final id = r['id'];
        return id is String &&
            !destination.containsKey(id) &&
            id != 'generation-lock' &&
            !id.startsWith('usage-') &&
            !conflictingDocuments.contains(r['document']) &&
            !conflictingQuestions.contains(r['question']) &&
            !(r['questionIds'] is List &&
                (r['questionIds'] as List).any(conflictingQuestions.contains));
      })
      .map((r) => Map<String, dynamic>.from(r))
      .toList();
}

bool shouldLinkGuestCredential({
  required bool anonymous,
  required bool registering,
  required String provider,
}) => anonymous && (registering || provider != 'password');
