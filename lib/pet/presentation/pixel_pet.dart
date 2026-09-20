import 'package:flutter/material.dart';

import '../domain/pet_world.dart';
import 'pet_animation_catalog.dart';
import 'pixel_pet_sprite.dart';

class PixelPet extends StatelessWidget {
  const PixelPet({
    super.key,
    this.petType = PetType.corgi,
    required this.state,
    this.direction = 1.0,
    this.frameIndex = 0,
    Size? size,
  }) : _size = size;

  final PetType petType;
  final PetState state;
  final double direction;
  final int frameIndex;
  final Size? _size;

  Size get size =>
      _size ?? PetAnimationCatalog.resolve(petType, state).logicalSize;

  @override
  Widget build(BuildContext context) => PixelPetSprite(
    petType: petType,
    state: state,
    direction: direction,
    frameIndex: frameIndex,
    size: _size,
  );
}
