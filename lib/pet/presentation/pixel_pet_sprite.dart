import 'package:flutter/material.dart';

import '../domain/pet_world.dart';
import 'pet_animation_catalog.dart';

/// Helper to map [PetType], [PetState] and frame index to the corresponding asset file.
String petAssetFor(PetType petType, PetState state, int frameIndex) {
  return PetAnimationCatalog.resolve(petType, state).frameAt(frameIndex);
}

/// Helper to map [PetState] and frame index to the corresponding corgi asset file (backward compatible).
String corgiAssetFor(PetState state, int frameIndex) =>
    petAssetFor(PetType.corgi, state, frameIndex);

/// Metadata definition for the unified sprite sheet at `assets/pets/${petType}_sheet.png`.
/// Each frame in the 4x5 sheet is 128x128.
class CorgiSpriteSheet {
  static const double frameSize = 128;
  static const int columns = 4;
  static const int rows = 5;

  static Rect getFrameRect(PetState state, int frameIndex) {
    int row;
    int col;

    switch (state) {
      case PetState.idle:
        row = 0;
        col = frameIndex.abs() % 4;
        break;
      case PetState.walk:
        row = 1;
        col = frameIndex.abs() % 4;
        break;
      case PetState.run:
        row = 2;
        col = (frameIndex.abs() % 2) * 2;
        break;
      case PetState.jump:
      case PetState.pounce:
        row = 3;
        col = (frameIndex.abs() % 2) * 2;
        break;
      case PetState.observe:
        row = 4;
        col = (frameIndex.abs() % 2) * 2;
        break;
      case PetState.catStalk:
        row = 1;
        col = frameIndex.abs() % 4;
        break;
      case PetState.pawTest:
      case PetState.dogProbe:
      case PetState.parrotProbe:
        row = 4;
        col = (frameIndex.abs() % 2) * 2;
        break;
    }

    return Rect.fromLTWH(
      col * frameSize,
      row * frameSize,
      frameSize,
      frameSize,
    );
  }
}

/// A pixel-art sprite widget that renders the pet with nearest-neighbor scaling.
class PixelPetSprite extends StatelessWidget {
  const PixelPetSprite({
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
  Widget build(BuildContext context) {
    final spec = PetAnimationCatalog.resolve(petType, state);
    final assetPath = spec.frameAt(frameIndex);
    final isFacingLeft = direction < 0;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Transform.flip(
        flipX: isFacingLeft,
        child: Image.asset(
          assetPath,
          width: size.width,
          height: size.height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          isAntiAlias: false,
        ),
      ),
    );
  }
}
