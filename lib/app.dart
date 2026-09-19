import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat/presentation/chat_shell.dart';

class ChatPetApp extends StatelessWidget {
  const ChatPetApp({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
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
      home: const ChatShell(showDemoAttachments: true),
    ),
  );
}
