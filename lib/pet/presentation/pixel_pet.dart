import 'package:flutter/material.dart';

import '../domain/pet_world.dart';
import 'pixel_pet_sprite.dart';

class PixelPet extends StatelessWidget {
  const PixelPet({
    super.key,
    this.petType = PetType.corgi,
    required this.state,
    this.direction = 1.0,
    this.frameIndex = 0,
    this.size,
  });

  final PetType petType;
  final PetState state;
  final double direction;
  final int frameIndex;
  final Size? size;

  @override
  Widget build(BuildContext context) => PixelPetSprite(
    petType: petType,
    state: state,
    direction: direction,
    frameIndex: frameIndex,
    size: size,
  );
}
