import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/firebase/firebase_environment.dart';

void main() {
  test('fake is default and does not initialize Firebase', () {
    expect(FirebaseEnvironment.defaultMode, FirebaseEnvironmentMode.fake);
  });

  test('staging targets production project and Taiwan Functions region', () {
    final environment = FirebaseEnvironment.staging();

    expect(environment.mode, FirebaseEnvironmentMode.staging);
    expect(environment.projectId, 'pet-digit-backend');
    expect(environment.functionsRegion, 'asia-east1');
    expect(environment.usesBackendTransport, isTrue);
  });

  test('unknown transport fails closed', () {
    expect(
      () => FirebaseEnvironment.fromTransportValue('stagng'),
      throwsFormatException,
    );
  });

  test('staging fails closed before Firebase initialization is configured', () {
    expect(
      FirebaseEnvironment.staging().initialize(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Staging Firebase configuration is not available'),
        ),
      ),
    );
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
