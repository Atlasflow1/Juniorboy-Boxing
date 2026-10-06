import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/notification_service.dart';

class AuthRemoteDataSource {
  final auth = FirebaseAuth.instance;

  Stream<User?> userChanges() => auth.userChanges();
  User? get currentUser => auth.currentUser;

  // google_sign_in 7.x's Credential Manager flow on Android has a known,
  // reproducible regression (flutter/flutter#187395) where the account
  // picker silently fails to render and the call throws
  // GoogleSignInExceptionCode.canceled / "Account reauth failed". Staying
  // on the pre-7.0 API sidesteps Credential Manager entirely.
  final _googleSignIn = GoogleSignIn(
    serverClientId: const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue:
          '772438105367-q284tguvctru8ltf50np6nfck80rhmf3.apps.googleusercontent.com',
    ),
  );

  Future<void> initializeProfile() async {
    await FirebaseFunctions.instance.httpsCallable('initializeProfile').call();
  }

  Future<void> googleSignIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
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
