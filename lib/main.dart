import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase/firebase_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseEnvironment.fromDartDefine().initialize();
  runApp(const ChatPetApp());
}
