import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/pet_action_plan.dart';
import 'package:chat_pet_mvp/pet/domain/pet_action_runner.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';

void main() {
  group('PetActionRunner', () {
    test('fresh activation binds plan target payload and zeroed clocks', () {
      final target = _target('first');
      final plan = _plan(
        PetRuntimeAction.inspectMedia,
        target.id,
        payload: 'media',
      );
      final runner = PetActionRunner()..start(plan, target);

      expect(runner.activePlan, same(plan));
      expect(runner.target, same(target));
      expect(runner.payload, 'media');
      expect(runner.totalElapsed, Duration.zero);
      expect(runner.phaseElapsed, Duration.zero);
      expect(runner.lastEndReason, isNull);
    });

    test('replacement overwrites bindings and resets both clocks', () {
      final first = _target('first');
      final second = _target('second');
      final runner = PetActionRunner()
        ..start(
          _plan(PetRuntimeAction.inspectMedia, first.id, payload: 'old'),
          first,
        )
        ..advance(const Duration(milliseconds: 450))
        ..beginPhase()
        ..advance(const Duration(milliseconds: 80))
        ..start(
          _plan(PetRuntimeAction.chaseEmoji, second.id, payload: 'new'),
          second,
        );

      expect(runner.target, same(second));
      expect(runner.payload, 'new');
      expect(runner.totalElapsed, Duration.zero);
      expect(runner.phaseElapsed, Duration.zero);
      expect(runner.lastEndReason, PetActionEndReason.replaced);
    });

    test('beginPhase resets phase elapsed without resetting total elapsed', () {
      final target = _target('target');
      final runner = PetActionRunner()
        ..start(_plan(PetRuntimeAction.observeTarget, target.id), target)
        ..advance(const Duration(milliseconds: 640))
        ..beginPhase();

      expect(runner.totalElapsed, const Duration(milliseconds: 640));
      expect(runner.phaseElapsed, Duration.zero);
      runner.advance(const Duration(milliseconds: 90));
      expect(runner.totalElapsed, const Duration(milliseconds: 730));
      expect(runner.phaseElapsed, const Duration(milliseconds: 90));
    });

    test('natural completion applies explicit action retention policy', () {
      final cases =
          <({PetRuntimeAction action, bool retainTarget, bool retainPayload})>[
            (
              action: PetRuntimeAction.jumpToPlatform,
              retainTarget: true,
              retainPayload: false,
            ),
            (
              action: PetRuntimeAction.chaseEmoji,
              retainTarget: true,
              retainPayload: true,
            ),
            (
              action: PetRuntimeAction.inspectMedia,
              retainTarget: true,
              retainPayload: true,
            ),
            (
              action: PetRuntimeAction.observeTarget,
              retainTarget: false,
              retainPayload: false,
            ),
            (
              action: PetRuntimeAction.catPawTest,
              retainTarget: true,
              retainPayload: true,
            ),
            (
              action: PetRuntimeAction.dogProbe,
              retainTarget: true,
              retainPayload: true,
            ),
            (
              action: PetRuntimeAction.parrotProbe,
              retainTarget: true,
              retainPayload: true,
            ),
          ];

      for (final item in cases) {
        final target = _target(item.action.name);
        final runner = PetActionRunner()
          ..start(_plan(item.action, target.id, payload: 'payload'), target)
          ..advance(const Duration(milliseconds: 120))
          ..end(PetActionEndReason.completed);

        expect(runner.activePlan, isNull, reason: item.action.name);
        expect(runner.target, item.retainTarget ? same(target) : isNull);
        expect(runner.payload, item.retainPayload ? 'payload' : isNull);
        expect(runner.totalElapsed, Duration.zero);
        expect(runner.phaseElapsed, Duration.zero);
        expect(runner.lastEndReason, PetActionEndReason.completed);
      }
    });

    for (final reason in [
      PetActionEndReason.worldReset,
      PetActionEndReason.petChanged,
      PetActionEndReason.targetRemoved,
    ]) {
      test('$reason clears active and retained compatibility bindings', () {
        final target = _target('target');
        final runner = PetActionRunner()
          ..start(
            _plan(PetRuntimeAction.inspectMedia, target.id, payload: 'media'),
            target,
          )
          ..end(PetActionEndReason.completed)
          ..end(reason);

        expect(runner.activePlan, isNull);
        expect(runner.target, isNull);
        expect(runner.payload, isNull);
        expect(runner.totalElapsed, Duration.zero);
        expect(runner.phaseElapsed, Duration.zero);
        expect(runner.lastEndReason, reason);
      });
    }

    test('retarget preserves immutable origin and elapsed clocks', () {
      final original = _target('client');
      final replacement = _target('server');
      final plan = _plan(PetRuntimeAction.catPawTest, original.id);
      final runner = PetActionRunner()
        ..start(plan, original)
        ..advance(const Duration(milliseconds: 1990))
        ..retarget(replacement);

      expect(runner.activePlan, same(plan));
      expect(runner.activePlan?.originTargetId, 'client');
      expect(runner.target, same(replacement));
      expect(runner.totalElapsed, const Duration(milliseconds: 1990));
      expect(runner.phaseElapsed, const Duration(milliseconds: 1990));
      expect(runner.lastEndReason, isNull);
    });
  });
}

PetActionPlan _plan(
  PetRuntimeAction action,
  String originTargetId, {
  Object? payload,
}) => PetActionPlan(
  runtimeAction: action,
  catalogAction: PetBehaviorAction.headTiltFocus,
  originTargetId: originTargetId,
  payload: payload,
);

PetMessageTarget _target(String id) => PetMessageTarget(
  id: id,
  kind: WorldObjectKind.platform,
  contentKind: PetNormalizedContentKind.text,
  payload: id,
  messageText: id,
)..markMeasuredBounds(const Rect.fromLTWH(100, 200, 180, 52));
