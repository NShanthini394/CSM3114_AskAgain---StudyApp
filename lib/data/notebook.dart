import 'review_schedule.dart';
import 'guest_import.dart';
import 'appearance.dart';
import 'subject_styles.dart';
import 'study_content.dart' show dueQuestions;
import '../services/account_auth.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef StudyRecord = Map<String, dynamic>;
String today([DateTime? t]) =>
    (t ?? DateTime.now()).toLocal().toIso8601String().split('T').first;
int _idSequence = 0;
String newId() => '${DateTime.now().microsecondsSinceEpoch}-${_idSequence++}';

class Notebook extends ChangeNotifier {
  Notebook._(this.prefs, this.cloud);
  final SharedPreferences prefs;
  final bool cloud;
  bool active = false;
  bool get guest =>
      !cloud || FirebaseAuth.instance.currentUser?.isAnonymous == true;
  bool get profileComplete => profile['onboarded'] == true;
  bool get tutorialComplete => prefs.getBool('tutorialComplete') == true;
  Future<void> completeTutorial() async {
    await prefs.setBool('tutorialComplete', true);
    notifyListeners();
  }

  bool get guestTrialUsed => records.containsKey('guest-trial');
  bool get passwordAccount =>
      cloud &&
      FirebaseAuth.instance.currentUser!.providerData.any(
        (p) => p.providerId == 'password',
      );
  Map<String, StudyRecord> records = {};
  ThemeMode get theme =>
      ThemeMode.values.byName(prefs.getString('theme') ?? 'system');
  Future<void> setTheme(ThemeMode m) async {
    await prefs.setString('theme', m.name);
    notifyListeners();
  }

  String get fontFamily => savedFontFamily(prefs.getString('fontFamily'));
  String get textSize => savedTextSize(prefs.getString('textSize'));
  double get textScale => studyTextScale(textSize);

  Future<void> setFontFamily(String family) async {
    await prefs.setString('fontFamily', savedFontFamily(family));
    notifyListeners();
  }

  Future<void> setTextSize(String size) async {
    await prefs.setString('textSize', savedTextSize(size));
    notifyListeners();
  }

  static Future<Notebook> open() async {
    const key = String.fromEnvironment('FIREBASE_API_KEY');
    final configured =
        key.isNotEmpty ||
        await const MethodChannel('askagain/config')
                .invokeMethod<bool>('configured') ==
            true;
    if (key.isNotEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: key,
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
        ),
      );
    }
    if (configured && key.isEmpty) await Firebase.initializeApp();
    if (configured) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    }
    final b = Notebook._(await SharedPreferences.getInstance(), configured);
    if ((b.cloud && FirebaseAuth.instance.currentUser != null) ||
        (!b.cloud &&
            b.prefs.getBool('localOpen') == true &&
            b.prefs.getBool('guestChosen') == true)) {
      await b.load();
    }
    return b;
  }

  CollectionReference<StudyRecord> get collection => FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('records');
  List<StudyRecord> rows(String kind) =>
      records.values.where((e) => e['kind'] == kind).toList();
  StudyRecord get profile => records['profile'] ?? {};
  Future<void> load({bool notify = true}) async {
    if (cloud) {
      final snap = await collection.get();
      records = {for (final d in snap.docs) d.id: d.data()};
    } else {
      final data = jsonDecode(prefs.getString('notebook') ?? '{}') as Map;
      records = data.map(
        (k, v) => MapEntry(k as String, StudyRecord.from(v as Map)),
      );
      await prefs.setBool('localOpen', true);
    }
    active = true;
    if (cloud) await _resumeGuestImport();
    final styles = missingSubjectStyles(rows('subject'));
    if (styles.isNotEmpty) await change(styles, []);
    if (notify) notifyListeners();
  }

  Future<void> startGuest() async {
    if (cloud && FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await load(notify: false);
    if (!cloud) await prefs.setBool('guestChosen', true);
    if (cloud && guest && prefs.getString('notebook') != null) {
      final local = jsonDecode(prefs.getString('notebook')!) as Map;
      final imported = local.values
          .map((r) => StudyRecord.from(r as Map))
          .where((r) => !records.containsKey(r['id']))
          .toList();
      await change(imported, []);
      await prefs.remove('notebook');
      await prefs.setBool('localOpen', false);
    }
    if (profile.isEmpty) {
      await save({
        'id': 'profile',
        'kind': 'profile',
        'name': '',
        'level': 'Undergraduate',
        'language': 'English',
      });
    }
    notifyListeners();
  }

  void requireCloud() {
    if (!cloud) {
      throw StateError(
        'Account services will be available after Firebase is connected. Use Try as guest to explore.',
      );
    }
  }

  Future<void> finishProfile(String name, String level) async {
    await save({
      ...profile,
      'id': 'profile',
      'kind': 'profile',
      'name': name,
      'level': level,
      'onboarded': true,
    });
  }

  Future<void> _rememberGuest() async {
    if (!active && cloud && prefs.getString('notebook') != null) {
      await prefs.setString(
        'pendingGuestImport',
        jsonEncode({
          'source': 'local',
          'records': jsonDecode(prefs.getString('notebook')!),
        }),
      );
      return;
    }
    if (!active || !guest) return;
    await prefs.setString(
      'pendingGuestImport',
      jsonEncode({
        'source': cloud ? FirebaseAuth.instance.currentUser!.uid : 'local',
        'records': records,
      }),
    );
  }

  Future<void> _resumeGuestImport() async {
    if (guest) return;
    final saved = prefs.getString('pendingGuestImport');
    if (saved == null) return;
    final data = jsonDecode(saved) as Map;
    final source = data['source'] as String;
    final marker = 'import-$source';
    if (!records.containsKey(marker)) {
      final imported = guestRecordsToImport(
        Map<String, dynamic>.from(data['records']),
        records,
      );
      await change([
        ...imported,
        {'id': marker, 'kind': 'importReceipt'},
      ], []);
    }
    await prefs.remove('pendingGuestImport');
    if (source == 'local') {
      await prefs.remove('notebook');
      await prefs.setBool('localOpen', false);
    }
  }

  Future<void> _acceptCredential(
    AuthCredential credential, {
    bool register = false,
  }) async {
    final auth = FirebaseAuth.instance;
    await _rememberGuest();
    final current = auth.currentUser;
    if (shouldLinkGuestCredential(
      anonymous: current?.isAnonymous == true,
      registering: register,
      provider: credential.providerId,
    )) {
      try {
        await current!.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (![
          'credential-already-in-use',
          'email-already-in-use',
        ].contains(e.code)) {
          rethrow;
        }
        if (register) rethrow;
        await auth.signInWithCredential(credential);
      }
    } else if (register && credential is EmailAuthCredential) {
      await auth.createUserWithEmailAndPassword(
        email: credential.email,
        password: credential.password!,
      );
    } else {
      await auth.signInWithCredential(credential);
    }
    await load(notify: false);
    if (profile.isEmpty) {
      await save({
        'id': 'profile',
        'kind': 'profile',
        'name': auth.currentUser!.displayName ?? '',
        'level': 'Undergraduate',
        'language': 'English',
      });
    }
    notifyListeners();
  }

  Future<void> googleLogin() async {
    requireCloud();
    await _acceptCredential(await AccountAuth.googleCredential());
    final displayName = FirebaseAuth.instance.currentUser!.displayName;
    if (displayName != null && (profile['name'] ?? '').toString().isEmpty) {
      await save({...profile, 'name': displayName});
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool register = false,
    String name = '',
    String level = '',
    String language = '',
  }) async {
    requireCloud();
    await _acceptCredential(
      EmailAuthProvider.credential(email: email, password: password),
      register: register,
    );
  }

  Future<void> deleteAccount(String? password) async {
    if (cloud) {
      await AccountAuth.reauthenticate(password);
      // Read the authoritative cloud snapshot, including records created on another phone.
      final snapshot = await collection.get();
      for (var i = 0; i < snapshot.docs.length; i += 400) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshot.docs.skip(i).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .delete();
      await FirebaseAuth.instance.currentUser!.delete();
    }
    await prefs.remove('notebook');
    await prefs.remove('pendingGuestImport');
    await prefs.setBool('localOpen', false);
    records = {};
    active = false;
    notifyListeners();
  }

  Future<void> logout() async {
    if (cloud) await FirebaseAuth.instance.signOut();
    await prefs.setBool('localOpen', false);
    active = false;
    records = {};
    notifyListeners();
  }

  Future<void> save(StudyRecord row) => change([row], []);
  Future<void> change(List<StudyRecord> updates, List<String> deletes) async {
    updates = styledSubjectUpdates(records, updates);
    if (cloud) {
      final operations = <void Function(WriteBatch)>[
        for (final id in deletes) (batch) => batch.delete(collection.doc(id)),
        for (final row in updates)
          (batch) => batch.set(collection.doc(row['id']), row),
      ];
      for (var start = 0; start < operations.length; start += 400) {
        final batch = FirebaseFirestore.instance.batch();
        for (final apply in operations.skip(start).take(400)) {
          apply(batch);
        }
        await batch.commit();
      }
    }
    for (final id in deletes) {
      records.remove(id);
    }
    for (final row in updates) {
      records[row['id']] = row;
    }
    if (!cloud) await prefs.setString('notebook', jsonEncode(records));
    notifyListeners();
  }

  List<StudyRecord> get questions =>
      rows('question').where((q) => q['approved'] == true).toList();
  List<StudyRecord> get due => dueQuestions(questions, today());
  Future<void> rate(
    StudyRecord q,
    int rating,
    String mistake,
    String response, {
    String? session,
    String activity = 'practice',
  }) async {
    final ids = List<String>.from(q['_sourceIds'] ?? [q['id']]);
    final sources = ids
        .map((id) => records[id])
        .whereType<StudyRecord>()
        .toList();
    if (sources.isEmpty) {
      throw StateError(
        'The original question was removed. Start a new session.',
      );
    }
    await change([
      for (final source in sources)
        scheduledReview(source, rating, DateTime.now(), activity: activity),
      {
        'id': newId(),
        'kind': 'attempt',
        'question': q['id'],
        'questionIds': ids,
        'subject': q['subject'],
        'rating': rating,
        'mistake': mistake,
        'response': response,
        'date': today(),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'session': session ?? newId(),
        'chapter': q['chapter'] ?? '',
        'prompt': q['_sourceIds'] != null
            ? 'Matching round (${ids.length} pairs)'
            : q['studyPrompt'] ?? q['prompt'],
        'format': q['responseFormat'],
        'activity': activity,
      },
    ], []);
  }
}
