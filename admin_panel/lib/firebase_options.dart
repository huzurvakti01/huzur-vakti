import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('God Mode Admin only supports Flutter Web.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FIREBASE_WEB_API_KEY',
    appId: 'REPLACE_WITH_FIREBASE_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_FIREBASE_PROJECT_ID',
    authDomain: 'REPLACE_WITH_FIREBASE_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_WITH_FIREBASE_PROJECT_ID.appspot.com',
  );
}
