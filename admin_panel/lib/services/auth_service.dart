import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/logging/app_logger.dart';
import 'functions_service.dart';

class AuthService extends ChangeNotifier {
  AuthService({
    FirebaseAuth? auth,
    FunctionsService? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FunctionsService();

  final FirebaseAuth _auth;
  final FunctionsService _functions;

  User? _admin;
  bool _loading = true;
  bool _verifiedAdmin = false;

  User? get admin => _admin;
  bool get loading => _loading;
  bool get isSignedIn => _admin != null && _verifiedAdmin;

  Future<void> init() async {
    _admin = _auth.currentUser;

    if (_admin != null) {
      await _verifyAdmin();
    }

    _auth.authStateChanges().listen((user) async {
      _admin = user;
      _verifiedAdmin = false;

      if (user != null) {
        await _verifyAdmin();
      }

      _loading = false;
      notifyListeners();
    });

    _loading = false;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _admin = credential.user;
      await _verifyAdmin();

      if (!_verifiedAdmin) {
        await _auth.signOut();
        throw const AppException(
          'Bu e-posta adresinin God Mode admin yetkisi yok.',
          code: 'not_admin',
        );
      }
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Admin login failed',
        error: error,
        stackTrace: stackTrace,
        context: {'email': email},
      );

      throw AppException(
        'Giriş başarısız. E-posta, şifre veya admin yetkisini kontrol edin.',
        cause: error,
        stackTrace: stackTrace,
        code: 'admin_login_failed',
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _admin = null;
    _verifiedAdmin = false;
    notifyListeners();
  }

  Future<void> _verifyAdmin() async {
    try {
      final result = await _functions.assertAdmin();
      _verifiedAdmin = result['ok'] == true;
    } catch (error, stackTrace) {
      _verifiedAdmin = false;
      AppLogger.error(
        'Admin verification failed',
        error: error,
        stackTrace: stackTrace,
        context: {'email': _admin?.email},
      );
    }
  }
}
