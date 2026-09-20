import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'pet_effects.dart';
import 'pet_world.dart';

@immutable
class PetPresentationState {
  PetPresentationState({
    required this.petType,
    required this.petState,
    required this.position,
    required this.direction,
    required this.frameIndex,
    required this.surfaceY,
    required this.heightAboveSurface,
    required this.showActionBadge,
    required Iterable<PetPawPrintSnapshot> pawPrints,
    required Iterable<PetParticleSnapshot> mainParticles,
    required Iterable<PetParticleSnapshot> signatureParticles,
    required this.toy,
    required this.activeTarget,
  }) : pawPrints = List.unmodifiable(pawPrints),
       mainParticles = List.unmodifiable(mainParticles),
       signatureParticles = List.unmodifiable(signatureParticles);

  final PetType petType;
  final PetState petState;
  final Offset position;
  final double direction;
  final int frameIndex;
  final double surfaceY;
  final double heightAboveSurface;
  final bool showActionBadge;
  final List<PetPawPrintSnapshot> pawPrints;
  final List<PetParticleSnapshot> mainParticles;
  final List<PetParticleSnapshot> signatureParticles;
  final PetToySnapshot? toy;
  final PetTargetSnapshot? activeTarget;
}

@immutable
class PetParticleSnapshot {
  const PetParticleSnapshot({
    required this.position,
    required this.kind,
    required this.velocity,
    required this.opacity,
    required this.size,
  });

  factory PetParticleSnapshot.fromParticle(PetParticle particle) =>
      PetParticleSnapshot(
        position: particle.position,
        kind: particle.kind,
        velocity: particle.velocity,
        opacity: particle.opacity,
        size: particle.currentSize,
      );

  final Offset position;
  final ParticleKind kind;
  final Offset velocity;
  final double opacity;
  final double size;
}

@immutable
class PetPawPrintSnapshot {
  const PetPawPrintSnapshot({
    required this.position,
    required this.isLeftPaw,
    required this.direction,
    required this.opacity,
  });

  factory PetPawPrintSnapshot.fromPrint(PawPrint print) => PetPawPrintSnapshot(
    position: print.position,
    isLeftPaw: print.isLeftPaw,
    direction: print.direction,
    opacity: print.opacity,
  );

  final Offset position;
  final bool isLeftPaw;
  final double direction;
  final double opacity;
}

@immutable
class PetToySnapshot {
  const PetToySnapshot({
    required this.emoji,
    required this.position,
    required this.rotation,
  });

  factory PetToySnapshot.fromToy(BouncingEmojiToy toy) => PetToySnapshot(
    emoji: toy.emoji,
    position: toy.position,
    rotation: toy.rotation,
  );

  final String emoji;
  final Offset position;
  final double rotation;
}

@immutable
class PetTargetSnapshot {
  const PetTargetSnapshot({required this.id, required this.bounds});

  final String id;
  final Rect bounds;

  @override
  bool operator ==(Object other) =>
      other is PetTargetSnapshot && other.id == id && other.bounds == bounds;

  @override
  int get hashCode => Object.hash(id, bounds);
}
