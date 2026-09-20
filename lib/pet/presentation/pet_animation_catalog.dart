import '../domain/pet_world.dart';
import 'pet_animation_spec.dart';

abstract final class PetAnimationCatalog {
  static final Map<(PetType, PetState), PetAnimationSpec> _specs =
      Map.unmodifiable({
        for (final petType in PetType.values)
          for (final state in PetState.values)
            (petType, state): _buildSpec(petType, state),
      });

  static PetAnimationSpec resolve(PetType petType, PetState state) =>
      _specs[(petType, state)]!;

  static PetAnimationSpec _buildSpec(PetType petType, PetState state) {
    final prefix = petType.name;
    Iterable<String> sequence(String action, int length) sync* {
      for (var index = 0; index < length; index++) {
        yield 'assets/pets/${prefix}_${action}_$index.png';
      }
    }

    final frames = switch (state) {
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

    return PetAnimationSpec(
      key: '${petType.name}.${state.name}',
      frames: frames,
    );
  }
}
