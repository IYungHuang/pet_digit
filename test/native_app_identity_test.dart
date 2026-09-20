import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'com.iyunghuang.petdigitchat';
  test('all native targets use approved app identifier', () {
    final files = <String>[
      'macos/Runner/Configs/AppInfo.xcconfig',
      'macos/Runner.xcodeproj/project.pbxproj',
      'ios/Runner.xcodeproj/project.pbxproj',
      'android/app/build.gradle.kts',
    ];
    for (final path in files) {
      final content = File(path).readAsStringSync();
      expect(content, isNot(contains('com.example')), reason: path);
      expect(content, contains(id), reason: path);
    }
    expect(
      File(
        'android/app/src/main/kotlin/com/example/chat_pet_mvp/MainActivity.kt',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'android/app/src/main/kotlin/com/iyunghuang/petdigitchat/MainActivity.kt',
      ).readAsStringSync(),
      contains('package com.iyunghuang.petdigitchat'),
    );
  });
}
