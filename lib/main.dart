import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase/firebase_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final environment = FirebaseEnvironment.fromDartDefine();
    await environment.initialize();
    runApp(ChatPetApp(
      environment: environment,
      autoShowOnboarding: true,
    ));
  } catch (error) {
    runApp(FirebaseStartupFailureApp(message: error.toString()));
  }
}
