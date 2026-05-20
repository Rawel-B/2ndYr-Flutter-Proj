import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  static Future<bool> tryInitialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } on Object catch (error) {
      debugPrint('Firebase is not configured yet. Demo mode enabled: $error');
      return false;
    }
  }
}
