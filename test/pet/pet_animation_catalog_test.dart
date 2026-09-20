import 'dart:ui';

import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/presentation/pet_animation_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PetAnimationCatalog', () {
    for (final petType in PetType.values) {
      for (final state in PetState.values) {
        test('${petType.name}/${state.name} preserves exact mapping', () {
          final spec = PetAnimationCatalog.resolve(petType, state);
          final expected = _expectedFrames(petType, state);

          expect(spec.key, '${petType.name}.${state.name}');
          expect(spec.frames, expected);
          expect(spec.frames, isNotEmpty);
          expect(spec.logicalSize, const Size(64, 64));
          expect(spec.frameAt(-1), expected[1 % expected.length]);
          expect(
            spec.frameAt(expected.length + 2),
            expected[2 % expected.length],
          );
        });
      }
    }

    test('frames are immutable', () {
      final frames = PetAnimationCatalog.resolve(
        PetType.cat,
        PetState.pawTest,
      ).frames;

      expect(() => frames.add('other.png'), throwsUnsupportedError);
      expect(() => frames[0] = 'other.png', throwsUnsupportedError);
    });
  });
}

List<String> _expectedFrames(PetType petType, PetState state) {
  final prefix = petType.name;
  List<String> sequence(String action, int length) => [
    for (var index = 0; index < length; index++)
      'assets/pets/${prefix}_${action}_$index.png',
  ];

  return switch (state) {
    PetState.idle => sequence('idle', 4),
    PetState.walk => sequence('walk', 4),
    PetState.run => sequence('run', 2),
    PetState.jump || PetState.pounce => sequence('jump', 2),
    PetState.observe => sequence('observe', 2),
    PetState.catStalk when petType == PetType.cat => sequence('stalk', 4),
    PetState.catStalk => sequence('walk', 4),
    PetState.pawTest when petType == PetType.cat => sequence('paw_test', 6),
    PetState.pawTest => sequence('observe', 2),
    PetState.dogProbe when petType == PetType.corgi => sequence(
      'novel_probe',
      6,
    ),
    PetState.dogProbe => sequence('observe', 2),
    PetState.parrotProbe when petType == PetType.parrot => sequence(
      'novel_probe',
      6,
    ),
    PetState.parrotProbe => sequence('observe', 2),
  };
}
