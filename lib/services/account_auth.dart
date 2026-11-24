import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountAuth {
  static Future<void>? _googleReady;
  static Future<AuthCredential> googleCredential() async {
    final id = await const MethodChannel('askagain/config')
        .invokeMethod<String>('googleClientId');
    if (id == null || id.isEmpty) {
      throw StateError(
        'Enable Google sign-in in Firebase and download the updated google-services.json.',
      );
    }
    await (_googleReady ??= GoogleSignIn.instance.initialize(
      serverClientId: id,
    ));
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw StateError(
        'Google did not return a sign-in token. Please try again.',
      );
    }
    return GoogleAuthProvider.credential(idToken: token);
  }

  static Future<void> reauthenticate(String? password) async {
    final user = FirebaseAuth.instance.currentUser!;
    if (user.isAnonymous) return;
    if (user.providerData.any((p) => p.providerId == 'google.com')) {
      await user.reauthenticateWithCredential(await googleCredential());
    } else {
      if (password == null || password.isEmpty) {
        throw StateError('Enter your current password.');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    }
  }
}
