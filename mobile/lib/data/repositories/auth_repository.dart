import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_service.dart';

class AuthRepository {
  final auth = FirebaseAuth.instance;
  Future<void> initializeProfile() async {
    await FirebaseFunctions.instance.httpsCallable('initializeProfile').call();
  }

  Future<void> googleSignIn() async {
    await GoogleSignIn.instance.initialize(
      serverClientId: const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue:
            '772438105367-q284tguvctru8ltf50np6nfck80rhmf3.apps.googleusercontent.com',
      ),
    );
    final account = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    if (auth.currentUser?.isAnonymous == true) {
      try {
        await auth.currentUser!.linkWithCredential(credential);
      } on FirebaseAuthException catch (error) {
        if (error.code != 'credential-already-in-use') rethrow;
        await auth.signInWithCredential(credential);
      }
    } else {
      await auth.signInWithCredential(credential);
    }
    await initializeProfile();
  }

  Future<void> continueAsGuest() async {
    await auth.signInAnonymously();
    await initializeProfile();
  }

  Future<void> signOut() async {
    try {
      await NotificationService.instance.unregister();
    } catch (_) {
      // Signing out must remain available when the device is offline.
    }
    await auth.signOut();
    await Hive.box('jbb_cache').clear();
  }
}
