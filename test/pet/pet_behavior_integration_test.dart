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
    test('new message selects $action for $species without fake motion', () {
      final controller = _RecordingController()
        ..setPet(species)
        ..setMessageBubbleTargets([_message('history')]);
      expect(controller.results, isEmpty);
      final position = controller.position;
      final particles = controller.particles.toList();

      controller.setMessageBubbleTargets([
        _message('history'),
        _message('new'),
      ]);
      expect(controller.results, hasLength(1));
      expect(
        controller.stimuli.single.stimulusType,
        PetStimulusType.newMessageBubble,
      );
      expect(controller.results.single.action, action);
      controller.updateObjectBounds({'new': _bounds});
      expect(controller.results, hasLength(2));
      expect(controller.results.last.action, action);
      expect(
        controller.results.last.status,
        PetBehaviorExecutionStatus.ignored,
      );
      expect(controller.results.last.reason, contains('unsupported action'));
      expect(controller.currentAction, PetActionType.none);
      expect(controller.activeTarget, isNull);
      expect(controller.position, position);
      expect(controller.particles, particles);
    });

    for (final (content, runtime) in [
      (
        const MessageContent.text(text: 'platform'),
        PetActionType.jumpToPlatform,
      ),
      (const MessageContent.text(text: '🎾'), PetActionType.chaseEmoji),
      (
        const MessageContent.video(
          url: 'https://example.test/pet.gif',
          mimeType: 'image/gif',
        ),
        PetActionType.inspectGif,
      ),
    ]) {
      test('unsupported $species arrival preserves active $runtime tap', () {
        final tap = _message('tap').copyWith(content: content);
        final controller = _RecordingController()
          ..setPet(species)
          ..setMessageBubbleTargets([tap])
          ..updateObjectBounds({'tap': _bounds})
          ..interact('tap')
          ..tick(const Duration(milliseconds: 100));
        expect(controller.currentAction, runtime);
        expect(controller.stimuli.single.stimulusType, PetStimulusType.userTap);
        final position = controller.position;
        final state = controller.state;
        final payload = controller.activePayload;
        final toy = controller.bouncingToy;
        final particles = controller.particles.toList();

        controller.setMessageBubbleTargets([tap, _message('new')]);
        expect(controller.results, hasLength(2));
        expect(controller.results.last.action, action);
        controller.updateObjectBounds({'new': _bounds});
        expect(controller.results, hasLength(2));
        expect(controller.currentAction, runtime);
        expect(controller.activeTarget, same(controller.objects.first));
        expect(controller.activeTarget?.id, 'tap');
        expect(controller.position, position);
        expect(controller.state, state);
        expect(controller.activePayload, payload);
        expect(controller.bouncingToy, same(toy));
        expect(controller.particles, particles);

        // A ready unsupported event must also leave the running tap intact.
        controller.dispatch(controller.stimuli.last);
        expect(
          controller.results.last.status,
          PetBehaviorExecutionStatus.ignored,
        );
        expect(controller.results.last.reason, contains('unsupported action'));
        expect(controller.currentAction, runtime);
        expect(controller.position, position);
        expect(controller.bouncingToy, same(toy));
      });
    }
  }

  test(
    'each target dispatches independently; only latest unready event retries',
    () {
      final controller = _RecordingController()..setMessageBubbleTargets([]);
      final messages = [
        _message('first'),
        _message('second', serverId: 'server-second'),
        _message(
          'emoji',
        ).copyWith(content: const MessageContent.text(text: '🎾')),
        _message('media').copyWith(
          content: const MessageContent.image(
            url: 'https://example.test/pet.png',
            mimeType: 'image/png',
          ),
        ),
        _message('last'),
      ];
      controller.setMessageBubbleTargets(messages);
      expect(controller.results.map((result) => result.targetId), [
        'first',
        'server-second',
        'emoji',
        'media',
        'last',
      ]);
      expect(controller.stimuli.map((stimulus) => stimulus.sourceIdentity), [
        (roomId: 'room', clientId: 'first'),
        (roomId: 'room', clientId: 'second'),
        (roomId: 'room', clientId: 'emoji'),
        (roomId: 'room', clientId: 'media'),
        (roomId: 'room', clientId: 'last'),
      ]);
      expect(controller.results[2].action, isNull);
      expect(controller.results[3].action, isNull);
      controller.updateObjectBounds({
        for (final id in ['first', 'server-second', 'emoji', 'media'])
          id: _bounds,
      });
      expect(controller.results, hasLength(5));
      controller.setMessageBubbleTargets([
        ...messages.take(4),
        _message('last', serverId: 'server-last'),
      ]);
      expect(controller.results, hasLength(5));
      controller.updateObjectBounds({'server-last': _bounds});
      expect(controller.results, hasLength(6));
      expect(controller.results.last.targetId, 'server-last');
      expect(controller.results.last.reason, contains('unsupported action'));
      controller.updateObjectBounds({'server-last': _bounds, 'first': _bounds});
      expect(controller.results, hasLength(6));
      expect(controller.currentAction, PetActionType.none);
    },
  );

  test(
    'history, rebuild, edits, reorder and acknowledgement are not arrivals',
    () {
      final controller = _RecordingController()
        ..loadRoom(_room)
        ..setMessageBubbleTargets([_message('first'), _message('second')])
        ..updateObjectBounds({'first': _bounds, 'second': _bounds});
      expect(controller.results, isEmpty);
      controller.setMessageBubbleTargets([
        _message('second', text: 'edited'),
        _message('first', serverId: 'server-first'),
        _message('new'),
      ]);
      expect(controller.results, hasLength(1));
      expect(controller.results.single.targetId, 'new');
      controller.setMessageBubbleTargets([
        _message('new'),
        _message('first', serverId: 'server-first'),
        _message('second', text: 'edited'),
      ]);
      expect(controller.results, hasLength(1));
    },
  );

  test('room installation resets baseline and pending arrival', () {
    final controller = _RecordingController()
      ..setMessageBubbleTargets([_message('history')])
      ..setMessageBubbleTargets([_message('history'), _message('new')]);
    expect(controller.results, hasLength(1));
    controller.loadRoom(_room);
    controller.setMessageBubbleTargets([
      _message('new'),
      _message('history-2'),
    ]);
    controller.updateObjectBounds({'new': _bounds, 'history-2': _bounds});
    expect(controller.results, hasLength(1));
    controller.setMessageBubbleTargets([
      _message('new'),
      _message('history-2'),
      _message('live'),
    ]);
    expect(controller.results, hasLength(2));
    expect(controller.results.last.targetId, 'live');
  });

  test('different room snapshot establishes fresh baseline without replay', () {
    final controller = _RecordingController()
      ..setMessageBubbleTargets([_message('history')])
      ..setMessageBubbleTargets([_message('history'), _message('live')]);
    expect(controller.results, hasLength(1));
    controller.setMessageBubbleTargets([
      _message('other-history').copyWith(roomId: 'other-room'),
    ]);
    expect(controller.results, hasLength(1));
    controller.updateObjectBounds({'other-history': _bounds});
    expect(controller.results, hasLength(1));
  });
}

// Records boundary events and real execution outcomes; never replaces execution.
class _RecordingController extends PetWorldController {
  final stimuli = <PetBehaviorStimulus>[];
  final results = <PetBehaviorExecutionResult>[];

  @override
  PetBehaviorExecutionResult dispatch(PetBehaviorStimulus stimulus) {
    expect(objects.any((target) => target.id == stimulus.targetId), isTrue);
    stimuli.add(stimulus);
    final result = super.dispatch(stimulus);
    results.add(result);
    return result;
  }
}

ChatMessage _message(
  String clientId, {
  String? serverId,
  String text = 'hello',
}) => ChatMessage(
  clientId: clientId,
  serverId: serverId,
  roomId: 'room',
  senderId: 'sender',
  content: MessageContent.text(text: text),
  createdAt: DateTime(2026, 9, 19),
);

const _room = legacy.ChatRoom(
  id: 'room',
  name: 'Room',
  subtitle: '',
  messages: [],
);
