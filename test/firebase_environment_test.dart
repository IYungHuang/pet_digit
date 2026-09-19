import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/firebase/firebase_environment.dart';

void main() {
  test('fake is default and does not initialize Firebase', () {
    expect(FirebaseEnvironment.defaultMode, FirebaseEnvironmentMode.fake);
  });

  test('reads emulator ports from backend firebase.json shape', () {
    final environment = FirebaseEnvironment.fromBackendFirebaseJson(
      jsonDecode('''
        {"emulators":{"auth":{"port":9099},"firestore":{"port":8080},"storage":{"port":9199},"functions":{"port":5001}}}
      ''')
          as Map<String, dynamic>,
    );

    expect(environment.mode, FirebaseEnvironmentMode.emulator);
    expect(environment.projectId, 'demo-pet-digit');
    expect(environment.authHost, '127.0.0.1:9099');
    expect(environment.firestoreHost, '127.0.0.1:8080');
    expect(environment.storageHost, '127.0.0.1:9199');
    expect(environment.functionsHost, '127.0.0.1:5001');
  });
}
