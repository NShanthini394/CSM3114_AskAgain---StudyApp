import 'dart:io';

import 'package:askagain/data/guest_import.dart';

void main() {
  void check(bool value, String label) {
    if (!value) throw StateError(label);
    stdout.writeln('PASS $label');
  }

  final source = <String, dynamic>{
    'profile': {'id': 'profile', 'name': 'Guest'},
    'q': {'id': 'q', 'kind': 'question', 'prompt': 'A new question'},
    'guest-trial': {'id': 'guest-trial', 'kind': 'trial'},
    'generation-lock': {'id': 'generation-lock'},
    'usage-20261119': {'id': 'usage-20261119'},
  };
  final target = <String, dynamic>{
    'profile': {'id': 'profile', 'name': 'Existing user'},
  };
  final imported = guestRecordsToImport(source, target);
  check(
    imported.any((r) => r['id'] == 'q') &&
        !imported.any((r) => r['id'] == 'profile'),
    'Guest questions transfer while the existing account profile is retained',
  );
  check(
    !imported.any(
      (r) => r['id'] == 'generation-lock' || r['id'] == 'usage-20261119',
    ),
    'Temporary locks and source daily counters are excluded',
  );
  check(
    imported.any((r) => r['id'] == 'guest-trial'),
    'Trial receipt survives conversion',
  );
  final merged = <String, dynamic>{
    ...target,
    for (final r in imported) r['id'] as String: r,
  };
  check(
    guestRecordsToImport(source, merged).isEmpty,
    'Retrying an import does not duplicate existing records',
  );
  final duplicate = {
    'd': {'id': 'd', 'kind': 'document'},
    'dq': {'id': 'dq', 'kind': 'question', 'document': 'd'},
    'a': {'id': 'a', 'kind': 'attempt', 'question': 'dq'},
  };
  check(
    guestRecordsToImport(duplicate, {
      'd': {'id': 'd'},
    }).isEmpty,
    'Duplicate source documents cannot attach guest history to unrelated target questions',
  );
  check(
    !guestRecordsToImport(
      {
        ...duplicate,
        'round': {
          'id': 'round',
          'kind': 'attempt',
          'question': 'another-question',
          'questionIds': ['another-question', 'dq'],
        },
      },
      {
        'd': {'id': 'd'},
      },
    ).any((r) => r['id'] == 'round'),
    'Matching history cannot attach conflicting secondary source questions',
  );
  check(
    !shouldLinkGuestCredential(
      anonymous: true,
      registering: false,
      provider: 'password',
    ),
    'Email sign-in never silently creates an account',
  );
  check(
    shouldLinkGuestCredential(
      anonymous: true,
      registering: true,
      provider: 'password',
    ),
    'Email registration upgrades the anonymous identity',
  );
  check(
    shouldLinkGuestCredential(
      anonymous: true,
      registering: false,
      provider: 'google.com',
    ),
    'Google sign-in can upgrade the anonymous identity',
  );
}
