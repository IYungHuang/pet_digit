import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';
import 'firebase_options_staging.dart';

const firebaseFunctionsRegion = 'asia-east1';

enum FirebaseEnvironmentMode { fake, emulator, staging }

class FirebaseEnvironment {
  const FirebaseEnvironment({
    required this.mode,
    this.projectId = 'demo-pet-digit',
    this.authHost = '127.0.0.1:9099',
    this.firestoreHost = '127.0.0.1:8080',
    this.storageHost = '127.0.0.1:9199',
    this.functionsHost = '127.0.0.1:5001',
    this.functionsRegion = firebaseFunctionsRegion,
  });

  static const defaultMode = FirebaseEnvironmentMode.fake;

  final FirebaseEnvironmentMode mode;
  final String projectId;
  final String authHost;
  final String firestoreHost;
  final String storageHost;
  final String functionsHost;
  final String functionsRegion;

  bool get usesBackendTransport => mode != FirebaseEnvironmentMode.fake;

  static FirebaseEnvironment fromDartDefine() {
    const value = String.fromEnvironment(
      'CHAT_TRANSPORT',
      defaultValue: 'fake',
    );
    return fromTransportValue(value);
  }

  static FirebaseEnvironment fromTransportValue(String value) =>
      switch (value) {
        'fake' => const FirebaseEnvironment(mode: FirebaseEnvironmentMode.fake),
        'emulator' => localEmulator(),
        'staging' => staging(),
        _ => throw FormatException('Unsupported CHAT_TRANSPORT: $value'),
      };

  /// Values mirror backend firebase.json. Use [fromBackendFirebaseJson] when
  /// ports change; this factory keeps app default fake and credentials local.
  static FirebaseEnvironment localEmulator() =>
      const FirebaseEnvironment(mode: FirebaseEnvironmentMode.emulator);

  static FirebaseEnvironment staging() => const FirebaseEnvironment(
    mode: FirebaseEnvironmentMode.staging,
    projectId: 'pet-digit-backend',
  );

  factory FirebaseEnvironment.fromBackendFirebaseJson(
    Map<String, dynamic> json,
  ) {
    final emulators = _map(json['emulators']);
    return FirebaseEnvironment(
      mode: FirebaseEnvironmentMode.emulator,
      authHost: _host(emulators, 'auth', 9099),
      firestoreHost: _host(emulators, 'firestore', 8080),
      storageHost: _host(emulators, 'storage', 9199),
      functionsHost: _host(emulators, 'functions', 5001),
    );
  }

  Future<void> initialize() async {
    if (mode == FirebaseEnvironmentMode.fake) return;
    if (mode == FirebaseEnvironmentMode.staging) {
      FirebaseBootstrapPolicy.validateAppCheckMode(
        staging: true,
        debugBuild: kDebugMode,
      );
      await Firebase.initializeApp(
        options: StagingFirebaseOptions.currentPlatform,
      );
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.debug,
        androidProvider: AndroidProvider.debug,
      );
      await ensureAnonymousFirebaseUser(
        hasCurrentUser: FirebaseAuth.instance.currentUser != null,
        signInAnonymously: () async {
          await FirebaseAuth.instance.signInAnonymously();
        },
      );
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:1234567890:ios:1234567890abcdef',
          messagingSenderId: 'demo-sender-id',
          projectId: 'demo-pet-digit',
          storageBucket: 'demo-pet-digit.appspot.com',
        ),
      );
    }

    final auth = _splitHost(authHost);
    await FirebaseAuth.instance.useAuthEmulator(auth.host, auth.port);
    final firestore = _splitHost(firestoreHost);
    FirebaseFirestore.instance.useFirestoreEmulator(
      firestore.host,
      firestore.port,
    );
    final storage = _splitHost(storageHost);
    FirebaseStorage.instance.useStorageEmulator(storage.host, storage.port);
    final functions = _splitHost(functionsHost);
    FirebaseFunctions.instanceFor(
      region: functionsRegion,
    ).useFunctionsEmulator(functions.host, functions.port);
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static String _host(
    Map<String, dynamic> emulators,
    String service,
    int fallbackPort,
  ) {
    final config = _map(emulators[service]);
    final host = config['host'] as String? ?? '127.0.0.1';
    final port = config['port'] as int? ?? fallbackPort;
    return '$host:$port';
  }

  static ({String host, int port}) _splitHost(String value) {
    final separator = value.lastIndexOf(':');
    if (separator <= 0) throw FormatException('Invalid emulator host: $value');
    return (
      host: value.substring(0, separator),
      port: int.parse(value.substring(separator + 1)),
    );
  }
}
