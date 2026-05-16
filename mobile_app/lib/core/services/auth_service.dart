import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../constants/app_strings.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

class AuthService extends ChangeNotifier {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  User? _user;
  bool _loading = false;

  User? get user => _user ?? _auth.currentUser;
  bool get isSignedIn => user != null && !(user?.isAnonymous ?? false);
  bool get isGuest => user?.isAnonymous ?? false;
  bool get loading => _loading;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> init() async {
    _user = _auth.currentUser;

    _auth.authStateChanges().listen(
      (next) {
        _user = next;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          AppStrings.logAuthStateFailed,
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    _setLoading(true);

    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const AppException(
          AppStrings.authFailed,
          code: 'google_sign_in_cancelled',
        );
      }

      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      _user = result.user;
      notifyListeners();
      return result;
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logGoogleSignInFailed,
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.authFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'google_sign_in_failed',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential> signInWithApple() async {
    _setLoading(true);

    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256(rawNonce);

      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauth = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
      );

      final result = await _auth.signInWithCredential(oauth);
      _user = result.user;
      notifyListeners();
      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAppleSignInFailed,
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.authFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'apple_sign_in_failed',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential> continueAsGuest() async {
    _setLoading(true);

    try {
      final current = _auth.currentUser;
      if (current != null) {
        _user = current;
        notifyListeners();
        return Future.error(
          const AppException(
            AppStrings.guestSyncWarning,
            code: 'already_signed_in',
          ),
        );
      }

      final result = await _auth.signInAnonymously();
      _user = result.user;
      notifyListeners();
      return result;
    } catch (error, stackTrace) {
      if (error is AppException) rethrow;

      AppLogger.error(
        AppStrings.logAuthStateFailed,
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.authFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'guest_sign_in_failed',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    _setLoading(true);

    try {
      final current = _auth.currentUser;

      if (current == null) {
        throw const AppException(
          AppStrings.authFailed,
          code: 'delete_account_no_user',
        );
      }

      await current.delete();
      await _googleSignIn.signOut();
      _user = null;
      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.deleteAccountFailed,
        error: error,
        stackTrace: stackTrace,
      );

      throw AppException(
        AppStrings.deleteAccountFailed,
        cause: error,
        stackTrace: stackTrace,
        code: 'delete_account_failed',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (error, stackTrace) {
      AppLogger.error(
        AppStrings.logAuthStateFailed,
        error: error,
        stackTrace: stackTrace,
      );
      throw AppException(
        AppStrings.genericError,
        cause: error,
        stackTrace: stackTrace,
        code: 'sign_out_failed',
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();

    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
