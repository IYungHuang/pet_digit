import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class PetAnimationSpec {
  PetAnimationSpec({
    required this.key,
    required Iterable<String> frames,
    this.logicalSize = const Size(64, 64),
  }) : assert(frames.isNotEmpty),
       frames = List.unmodifiable(frames);

  final String key;
  final List<String> frames;
  final Size logicalSize;

  String frameAt(int index) => frames[index.abs() % frames.length];
}
