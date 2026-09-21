import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat/presentation/chat_shell.dart';
import 'chat/presentation/chat_providers.dart';
import 'firebase/firebase_environment.dart';

class ChatPetApp extends StatelessWidget {
  const ChatPetApp({
    super.key,
    this.environment = const FirebaseEnvironment(
      mode: FirebaseEnvironmentMode.fake,
    ),
    this.autoShowOnboarding = false,
  });

  final FirebaseEnvironment environment;
  final bool autoShowOnboarding;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [firebaseEnvironmentProvider.overrideWithValue(environment)],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat Pet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6c63ff),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff6f7fb),
        useMaterial3: true,
      ),
      home: ChatShell(
        showDemoAttachments: true,
        autoShowOnboarding: autoShowOnboarding,
      ),
    ),
  );
}

class FirebaseStartupFailureApp extends StatelessWidget {
  const FirebaseStartupFailureApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: Text(message))),
  );
}
