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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSSQvedn8sC8dmRyKu8_MAvPYBqKxk_4g',
    appId: '1:473616221902:android:2b351d8404aca9e53a729f',
    messagingSenderId: '473616221902',
    projectId: 'pet-digit-backend',
    storageBucket: 'pet-digit-backend.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Staging Firebase options are not configured for web.',
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => apple,
      TargetPlatform.android => android,
      _ => throw UnsupportedError(
        'Staging Firebase options are not configured for this platform.',
      ),
    };
  }
}
