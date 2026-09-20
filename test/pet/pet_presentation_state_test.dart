import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_effects.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_presentation_state.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';

void main() {
  test('projects complete ordered render state without runtime references', () {
    final controller = PetWorldController()
      ..selectedPet = PetType.cat
      ..position = const Offset(31, 47)
      ..state = PetState.pawTest;
    final target = _target('client');
    controller.objects = [target];
    controller.startPawTest(target);
    controller.tick(const Duration(milliseconds: 1800));
    controller
      ..pawPrints.addAll([
        PawPrint(position: const Offset(1, 2), isLeftPaw: true, direction: -1),
        PawPrint(position: const Offset(3, 4), isLeftPaw: false, direction: 1),
      ])
      ..particles.addAll([
        PetParticle(
          position: const Offset(5, 6),
          kind: ParticleKind.heart,
          velocity: const Offset(7, 8),
        ),
        PetParticle(
          position: const Offset(9, 10),
          kind: ParticleKind.dust,
          velocity: const Offset(11, 12),
        ),
        PetParticle(position: const Offset(13, 14), kind: ParticleKind.note),
      ])
      ..bouncingToy = BouncingEmojiToy(
        emoji: '🎾',
        start: const Offset(15, 16),
        groundY: 90,
        direction: -1,
      );

    final state = controller.presentationState;

    expect(state.petType, PetType.cat);
    expect(state.petState, PetState.pawTest);
    expect(state.position, controller.position);
    expect(state.direction, 1);
    expect(state.frameIndex, 0);
    expect(state.surfaceY, controller.currentSurfaceY);
    expect(state.heightAboveSurface, 0);
    expect(state.showActionBadge, isTrue);
    expect(
      state.activeTarget,
      const PetTargetSnapshot(id: 'client', bounds: _bounds),
    );
    expect(state.pawPrints.map((p) => p.position), [
      const Offset(1, 2),
      const Offset(3, 4),
    ]);
    expect(state.pawPrints.map((p) => p.isLeftPaw), [true, false]);
    expect(state.mainParticles.map((p) => p.kind), [ParticleKind.dust]);
    expect(state.signatureParticles.map((p) => p.kind), [
      ParticleKind.heart,
      ParticleKind.note,
    ]);
    expect(state.signatureParticles.first.velocity, const Offset(7, 8));
    expect(state.toy?.emoji, '🎾');
    expect(state.toy?.position, const Offset(15, 16));
    expect(state.toy?.rotation, 0);
    expect(
      () => state.pawPrints.add(state.pawPrints.first),
      throwsUnsupportedError,
    );
    expect(
      () => state.mainParticles.add(state.mainParticles.first),
      throwsUnsupportedError,
    );
    expect(
      () => state.signatureParticles.add(state.signatureParticles.first),
      throwsUnsupportedError,
    );
  });

  test(
    'held snapshot is unchanged after ticks and canonical reconciliation',
    () {
      const source = (roomId: 'room', clientId: 'client');
      final client = _target('client', sourceIdentity: source);
      final controller = PetWorldController()
        ..objects = [client]
        ..startPawTest(client)
        ..pawPrints.add(
          PawPrint(
            position: const Offset(20, 30),
            isLeftPaw: true,
            direction: 1,
          ),
        )
        ..particles.add(
          PetParticle(position: const Offset(40, 50), kind: ParticleKind.dust),
        )
        ..bouncingToy = BouncingEmojiToy(
          emoji: '🧶',
          start: const Offset(60, 70),
          groundY: 100,
          direction: 1,
        );
      final before = controller.presentationState;
      final beforePrint = before.pawPrints.single;
      final beforeParticle = before.mainParticles.single;
      final beforeToy = before.toy!;

      controller.tick(const Duration(milliseconds: 100));
      final server = _target('server', sourceIdentity: source);
      controller.objects = [server];
      controller.updateObjectBounds({
        'server': const Rect.fromLTWH(8, 9, 10, 11),
      });

      expect(
        before.activeTarget,
        const PetTargetSnapshot(id: 'client', bounds: _bounds),
      );
      expect(beforePrint.opacity, 1);
      expect(beforeParticle.position, const Offset(40, 50));
      expect(beforeParticle.opacity, 1);
      expect(beforeToy.position, const Offset(60, 70));
      expect(beforeToy.rotation, 0);
      expect(controller.presentationState.activeTarget?.id, 'server');
      expect(
        controller.presentationState.activeTarget?.bounds,
        const Rect.fromLTWH(8, 9, 10, 11),
      );
    },
  );
}

const _bounds = Rect.fromLTWH(100, 200, 180, 52);

PetMessageTarget _target(
  String id, {
  ({String roomId, String clientId})? sourceIdentity,
}) => PetMessageTarget(
  id: id,
  kind: WorldObjectKind.animatedToy,
  contentKind: PetNormalizedContentKind.gif,
  payload: 'media',
  messageText: 'media',
  sourceIdentity: sourceIdentity,
)..markMeasuredBounds(_bounds);
