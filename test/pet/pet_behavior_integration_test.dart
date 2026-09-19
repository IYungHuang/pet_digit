import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/domain/chat_message.dart';
import 'package:chat_pet_mvp/chat/domain/chat_models.dart' as legacy;
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_executor.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';

const _bounds = Rect.fromLTWH(100, 200, 180, 52);

void main() {
  for (final (species, action) in [
    (PetType.corgi, PetBehaviorAction.approachArc),
    (PetType.cat, PetBehaviorAction.approachLowSilent),
    (PetType.parrot, PetBehaviorAction.approachSideways),
  ]) {
    test('live text delta starts finite light approach for $species', () {
      final controller = _RecordingController()
        ..setPet(species)
        ..setMessageBubbleTargets([_message('history')], roomId: 'room');

      controller.handleMessageAdded(_message('new'), isLive: true);
      expect(controller.results.single.action, action);
      expect(
        controller.results.single.status,
        PetBehaviorExecutionStatus.ignored,
      );

      controller.updateObjectBounds({'new': _bounds});
      expect(
        controller.results.last.status,
        PetBehaviorExecutionStatus.fallback,
      );
      expect(controller.currentAction, PetActionType.observeTarget);

      controller.tick(const Duration(seconds: 10));
      expect(controller.state, PetState.observe);
      controller.tick(const Duration(milliseconds: 900));
      expect(controller.currentAction, PetActionType.none);
      expect(controller.state, PetState.idle);
    });
  }

  for (final (species, action, runtime) in [
    (
      PetType.corgi,
      PetBehaviorAction.novelObjectNoseProbe,
      PetActionType.dogProbe,
    ),
    (PetType.cat, PetBehaviorAction.pawTest, PetActionType.pawTest),
    (PetType.parrot, PetBehaviorAction.beakProbe, PetActionType.parrotProbe),
  ]) {
    test('live media delta starts native $species investigation', () {
      final controller = _RecordingController()
        ..setPet(species)
        ..setMessageBubbleTargets([_message('history')], roomId: 'room');
      final media = _message('media').copyWith(
        content: const MessageContent.image(
          url: 'https://example.test/new.png',
          mimeType: 'image/png',
        ),
      );

      controller.handleMessageAdded(media, isLive: true);
      expect(controller.results.single.action, action);
      expect(
        controller.results.single.status,
        PetBehaviorExecutionStatus.ignored,
      );
      controller.updateObjectBounds({'media': _bounds});

      expect(
        controller.results.last.status,
        PetBehaviorExecutionStatus.executed,
      );
      expect(controller.currentAction, runtime);
      expect(controller.activeTarget?.id, 'media');
    });
  }

  test(
    'snapshot history, reconnect backfill, and reintroduction stay silent',
    () {
      final controller = _RecordingController()
        ..setMessageBubbleTargets([_message('history')], roomId: 'room');

      controller.setMessageBubbleTargets([
        _message('history'),
        _message('backfill'),
      ], roomId: 'room');
      controller.handleMessageAdded(_message('backfill'), isLive: false);
      expect(controller.results, isEmpty);

      final live = _message('live');
      controller.handleMessageAdded(live, isLive: true);
      expect(controller.results, hasLength(1));
      controller.setMessageBubbleTargets([
        _message('history'),
        _message('backfill'),
      ], roomId: 'room');
      controller.setMessageBubbleTargets([
        _message('history'),
        _message('backfill'),
        live,
      ], roomId: 'room');
      controller.handleMessageAdded(live, isLive: true);
      expect(controller.results, hasLength(1));
    },
  );

  test('message arrival never interrupts an active user tap', () {
    final tap = _message(
      'tap',
    ).copyWith(content: const MessageContent.text(text: 'platform'));
    final controller = _RecordingController()
      ..setMessageBubbleTargets([tap], roomId: 'room')
      ..updateObjectBounds({'tap': _bounds})
      ..interact('tap');
    expect(controller.currentAction, PetActionType.jumpToPlatform);

    controller.handleMessageAdded(_message('new'), isLive: true);
    expect(controller.results.last.status, PetBehaviorExecutionStatus.ignored);
    expect(controller.results.last.reason, contains('active action'));
    expect(controller.currentAction, PetActionType.jumpToPlatform);
    expect(controller.activeTarget?.id, 'tap');
  });

  test('room change clears delta dedupe and establishes fresh history', () {
    final controller = _RecordingController()
      ..loadRoom(_room)
      ..setMessageBubbleTargets([_message('history')], roomId: 'room');
    controller.handleMessageAdded(_message('live'), isLive: true);
    expect(controller.results, hasLength(1));

    controller.loadRoom(
      const legacy.ChatRoom(
        id: 'other-room',
        name: 'Other',
        subtitle: '',
        messages: [],
      ),
    );
    controller.setMessageBubbleTargets([
      _message('live').copyWith(roomId: 'other-room'),
    ], roomId: 'other-room');
    controller.handleMessageAdded(
      _message('live').copyWith(roomId: 'other-room'),
      isLive: false,
    );
    expect(controller.results, hasLength(1));
  });
}

class _RecordingController extends PetWorldController {
  final stimuli = <PetBehaviorStimulus>[];
  final results = <PetBehaviorExecutionResult>[];

  @override
  PetBehaviorExecutionResult dispatch(PetBehaviorStimulus stimulus) {
    stimuli.add(stimulus);
    final result = super.dispatch(stimulus);
    results.add(result);
    return result;
  }
}

ChatMessage _message(String clientId) => ChatMessage(
  clientId: clientId,
  roomId: 'room',
  senderId: 'sender',
  content: const MessageContent.text(text: 'hello'),
  createdAt: DateTime(2026, 9, 19),
);

const _room = legacy.ChatRoom(
  id: 'room',
  name: 'Room',
  subtitle: '',
  messages: [],
);
