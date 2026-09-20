import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class StagingFirebaseOptions {
  static const FirebaseOptions apple = FirebaseOptions(
    apiKey: 'AIzaSyAw00zkpQ9oKHCS_2286VdyJdCYF1mB1Rw',
    appId: '1:473616221902:ios:5613d495e3d6f07c3a729f',
    messagingSenderId: '473616221902',
    projectId: 'pet-digit-backend',
    storageBucket: 'pet-digit-backend.firebasestorage.app',
    iosBundleId: 'com.iyunghuang.petdigitchat',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Staging Firebase options are not configured for web.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => apple,
      _ => throw UnsupportedError(
        'Staging Firebase options are not configured for this platform.',
      ),
    };
  }
}
