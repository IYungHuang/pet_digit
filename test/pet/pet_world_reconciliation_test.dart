import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/domain/chat_message.dart' as domain;
import 'package:chat_pet_mvp/chat/domain/chat_models.dart' as legacy;
import 'package:chat_pet_mvp/chat/domain/message_content.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_catalog.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_executor.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_normalizer.dart';
import 'package:chat_pet_mvp/pet/domain/pet_behavior_runtime.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_content_kind.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target.dart';
import 'package:chat_pet_mvp/pet/domain/pet_message_target_factory.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world.dart';
import 'package:chat_pet_mvp/pet/domain/pet_world_controller.dart';

const _bounds = Rect.fromLTWH(100, 200, 180, 52);

void main() {
  test('both message adapters store normalized unmeasured targets', () {
    final controller = PetWorldController()..loadRoom(_room);
    expect(controller.objects.single, isA<PetMessageTarget>());
    expect(controller.objects.single.payload, 'hello');
    expect(controller.objects.single.hasMeasuredBounds, isFalse);
    expect(
      controller.interact('legacy').status,
      PetBehaviorExecutionStatus.ignored,
    );

    controller.setMessageBubbleTargets([_message()]);
    expect(controller.objects.single, isA<PetMessageTarget>());
    expect(controller.objects.single.hasMeasuredBounds, isFalse);
  });

  test('same IDs refresh normalized payload and retain measured bounds', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message(text: '🎾')])
      ..updateObjectBounds({'client': _bounds});
    controller.setMessageBubbleTargets([_message(text: '🧶')]);
    controller.interact('client');
    expect(controller.bouncingToy?.emoji, '🧶');
    expect(controller.activeTarget, same(controller.objects.single));
    expect(controller.activeTarget?.bounds, _bounds);
  });

  test('bounds update retries pending stimulus once after measurement', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()]);
    expect(
      controller.interact('client').status,
      PetBehaviorExecutionStatus.ignored,
    );
    controller.updateObjectBounds({'unrelated': _bounds});
    expect(controller.currentAction, PetActionType.none);
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.jumpToPlatform);
    expect(controller.activeTarget, same(controller.objects.single));
    controller.tick(const Duration(milliseconds: 600));
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
    expect(controller.currentPlatform, same(controller.objects.single));
  });

  test('legacy bounds also retry pending stimulus', () {
    final controller = PetWorldController()..loadRoom(_room);
    expect(
      controller.interact('legacy').status,
      PetBehaviorExecutionStatus.ignored,
    );
    controller.updateObjectBounds({'legacy': _bounds});
    expect(controller.currentAction, PetActionType.jumpToPlatform);
  });

  test('pending stimulus follows client ID to server ID', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()])
      ..interact('client');
    controller.setMessageBubbleTargets([_message(serverId: 'server')]);
    controller.updateObjectBounds({'server': _bounds});
    expect(controller.currentAction, PetActionType.jumpToPlatform);
    expect(controller.activeTarget?.id, 'server');
    expect(controller.activeTarget, same(controller.objects.single));
  });

  test('canonical migration preserves landed target, readiness and spring', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()])
      ..updateObjectBounds({'client': _bounds})
      ..interact('client')
      ..tick(const Duration(milliseconds: 600))
      ..tick(const Duration(milliseconds: 16));
    final deflection = controller.getBubbleDeflection('client');
    expect(deflection, greaterThan(0));
    controller.setMessageBubbleTargets([_message(serverId: 'server')]);

    final live = controller.objects.single;
    expect(controller.activeTarget, same(live));
    expect(controller.currentPlatform, same(live));
    expect(live.id, 'server');
    expect(live.bounds, _bounds);
    expect(live.hasMeasuredBounds, isTrue);
    expect(controller.getBubbleDeflection('server'), deflection);
    expect(controller.getBubbleDeflection('client'), 0);

    controller.updateObjectBounds({
      'server': const Rect.fromLTWH(120, 300, 180, 52),
    });
    controller.tick(const Duration(milliseconds: 16));
    expect(
      controller.position.dy,
      closeTo(248 + controller.getBubbleDeflection('server'), 0.001),
    );
    controller.setMessageBubbleTargets([]);
    expect(controller.activeTarget, isNull);
    expect(controller.currentPlatform, isNull);
    expect(controller.getBubbleDeflection('server'), 0);
    expect(controller.state, PetState.idle);
  });

  test('canonical migration during jump lands on live canonical target', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()])
      ..updateObjectBounds({'client': _bounds})
      ..interact('client')
      ..tick(const Duration(milliseconds: 200));
    controller.setMessageBubbleTargets([_message(serverId: 'server')]);
    expect(controller.currentAction, PetActionType.jumpToPlatform);
    expect(controller.activeTarget, same(controller.objects.single));
    controller.updateObjectBounds({
      'server': const Rect.fromLTWH(120, 300, 180, 52),
    });
    controller.tick(const Duration(milliseconds: 400));
    expect(controller.currentPlatform, same(controller.objects.single));
    expect(controller.currentPlatform?.id, 'server');
    expect(controller.position.dy, 248);
  });

  for (final action in ['paw', 'dog probe', 'parrot probe']) {
    test(
      '$action canonical migration immediately before impact uses new spring',
      () {
        final controller = PetWorldController()
          ..setPet(switch (action) {
            'paw' => PetType.cat,
            'dog probe' => PetType.corgi,
            _ => PetType.parrot,
          })
          ..setMessageBubbleTargets([_message()])
          ..updateObjectBounds({'client': _bounds});
        final original = controller.objects.single;
        switch (action) {
          case 'paw':
            controller.startPawTest(original);
            controller.tick(const Duration(milliseconds: 1990));
          case 'dog probe':
            controller.startDogProbe(original);
            controller.tick(const Duration(milliseconds: 1690));
          case 'parrot probe':
            controller.startParrotProbe(original);
            controller.tick(const Duration(milliseconds: 1690));
        }

        controller.setMessageBubbleTargets([_message(serverId: 'server')]);
        const replacementBounds = Rect.fromLTWH(240, 360, 160, 60);
        controller.updateObjectBounds({'server': replacementBounds});
        controller.tick(const Duration(milliseconds: 20));

        expect(controller.activeTarget, same(controller.objects.single));
        expect(controller.activeTarget?.id, 'server');
        expect(controller.activeTarget?.bounds, replacementBounds);
        expect(controller.getBubbleDeflection('client'), 0);
        expect(controller.currentAction, isNot(PetActionType.none));
        controller.tick(const Duration(milliseconds: 16));
        expect(controller.getBubbleDeflection('server'), greaterThan(0));
      },
    );
  }

  test('action clock preserves world millisecond truncation per tick', () {
    final controller = PetWorldController()
      ..setPet(PetType.cat)
      ..setMessageBubbleTargets([_message()])
      ..updateObjectBounds({'client': _bounds});
    controller.startPawTest(controller.objects.single);
    final beforeImpact = controller.springNotifier.value;

    for (var index = 0; index < 121; index++) {
      controller.tick(const Duration(microseconds: 16666));
    }
    expect(controller.springNotifier.value, beforeImpact);

    for (var index = 0; index < 4; index++) {
      controller.tick(const Duration(microseconds: 16666));
    }
    expect(controller.springNotifier.value, greaterThan(beforeImpact));
  });

  test('same client ID in another room never inherits pending or bounds', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()])
      ..interact('client');
    controller.setMessageBubbleTargets([_message(roomId: 'another-room')]);
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
    controller.interact('client');
    controller.setMessageBubbleTargets([_message()]);
    expect(controller.activeTarget, isNull);
    expect(controller.objects.single.hasMeasuredBounds, isFalse);
  });

  test('spring notification observes atomic canonical reconciliation', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()])
      ..updateObjectBounds({'client': _bounds})
      ..interact('client')
      ..tick(const Duration(milliseconds: 600))
      ..tick(const Duration(milliseconds: 16));
    final deflection = controller.getBubbleDeflection('client');
    var notifications = 0;
    controller.springNotifier.addListener(() {
      notifications++;
      final target = controller.objects.single;
      expect(target.id, 'server');
      expect(target.hasMeasuredBounds, isTrue);
      expect(target.bounds, _bounds);
      expect(controller.activeTarget, same(target));
      expect(controller.currentPlatform, same(target));
      expect(controller.getBubbleDeflection('client'), 0);
      expect(controller.getBubbleDeflection('server'), deflection);
    });
    controller.setMessageTargets([
      PetMessageTargetFactory.fromDomainMessage(_message(serverId: 'server')),
    ]);
    expect(notifications, 1);
  });

  test('stale room stimulus preserves the current room active action', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message(roomId: 'room-a')]);
    final stale = PetBehaviorNormalizer.fromTarget(
      controller.objects.single,
      PetStimulusType.userTap,
      petType: PetType.corgi,
    );
    controller.setMessageBubbleTargets([
      _message(roomId: 'room-b'),
      _message(roomId: 'room-b', clientId: 'active', text: '🎾'),
    ]);
    controller.updateObjectBounds({'client': _bounds, 'active': _bounds});
    controller.interact('active');
    final active = controller.activeTarget;
    final toy = controller.bouncingToy;
    final position = controller.position;
    final state = controller.state;

    expect(
      controller.dispatch(stale).status,
      PetBehaviorExecutionStatus.ignored,
    );
    expect(controller.activeTarget, same(active));
    expect(controller.activePayload, '🎾');
    expect(controller.bouncingToy, same(toy));
    expect(controller.currentAction, PetActionType.chaseEmoji);
    expect(controller.state, state);
    expect(controller.position, position);
    controller.tick(const Duration(seconds: 10));
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
    expect(controller.activeTarget, same(active));
  });

  test('stale room stimulus preserves landed runtime and pending stimulus', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message(roomId: 'room-a')]);
    final stale = PetBehaviorNormalizer.fromTarget(
      controller.objects.single,
      PetStimulusType.userTap,
      petType: PetType.corgi,
    );
    controller.setMessageBubbleTargets([
      _message(roomId: 'room-b'),
      _message(roomId: 'room-b', clientId: 'platform'),
      _message(roomId: 'room-b', clientId: 'pending', text: '🎾'),
    ]);
    controller.updateObjectBounds({'platform': _bounds});
    controller.interact('platform');
    controller.tick(const Duration(milliseconds: 600));
    controller.tick(const Duration(milliseconds: 16));
    final platform = controller.currentPlatform;
    final position = controller.position;
    final deflection = controller.getBubbleDeflection('platform');
    controller.interact('pending');

    expect(
      controller.dispatch(stale).status,
      PetBehaviorExecutionStatus.ignored,
    );
    expect(controller.activeTarget, same(platform));
    expect(controller.currentPlatform, same(platform));
    expect(controller.currentAction, PetActionType.none);
    expect(controller.state, PetState.idle);
    expect(controller.position, position);
    expect(controller.getBubbleDeflection('platform'), deflection);

    controller.updateObjectBounds({'pending': _bounds});
    expect(controller.currentAction, PetActionType.chaseEmoji);
    expect(controller.activeTarget?.id, 'pending');
    expect(controller.bouncingToy?.emoji, '🎾');
    controller.tick(const Duration(seconds: 10));
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
    expect(controller.activeTarget?.id, 'pending');
  });

  test('pending retry rejects changed source under the same canonical ID', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([
        _message(clientId: 'first', serverId: 'server'),
      ])
      ..interact('server');
    controller.setMessageBubbleTargets([
      _message(clientId: 'second', serverId: 'server'),
    ]);
    controller.updateObjectBounds({'server': _bounds});
    expect(controller.currentAction, PetActionType.none);
    expect(controller.activeTarget, isNull);
  });

  test('stimulus without source cannot queue work for a domain target', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()]);
    const stimulus = PetBehaviorStimulus(
      stimulusType: PetStimulusType.userTap,
      petType: PetType.corgi,
      targetId: 'client',
      targetKind: WorldObjectKind.platform,
      contentKind: PetNormalizedContentKind.text,
      payload: 'hello',
    );
    expect(
      controller.dispatch(stimulus).status,
      PetBehaviorExecutionStatus.ignored,
    );
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
    expect(controller.activeTarget, isNull);
  });

  test('reordering identical content reconciles by source identity', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([
        _message(clientId: 'first'),
        _message(clientId: 'second'),
      ])
      ..updateObjectBounds({
        'first': _bounds,
        'second': const Rect.fromLTWH(20, 400, 200, 60),
      })
      ..interact('first');
    controller.setMessageBubbleTargets([
      _message(clientId: 'second', serverId: 'server-second'),
      _message(clientId: 'first', serverId: 'server-first'),
    ]);
    expect(controller.activeTarget, same(controller.objects.last));
    expect(controller.activeTarget?.id, 'server-first');
    expect(controller.objects.last.bounds, _bounds);
    expect(
      controller.objects.first.bounds,
      const Rect.fromLTWH(20, 400, 200, 60),
    );
  });

  test('unrelated replacement never inherits active target or bounds', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()])
      ..updateObjectBounds({'client': _bounds})
      ..interact('client');
    controller.setMessageBubbleTargets([_message(clientId: 'unrelated')]);
    expect(controller.activeTarget, isNull);
    expect(controller.currentAction, PetActionType.none);
    expect(controller.objects.single.hasMeasuredBounds, isFalse);
  });

  test('removed active emoji clears action, payload and toy', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message(text: '🎾')])
      ..updateObjectBounds({'client': _bounds})
      ..interact('client');
    expect(controller.bouncingToy, isNotNull);
    controller.setMessageBubbleTargets([]);
    expect(controller.currentAction, PetActionType.none);
    expect(controller.state, PetState.idle);
    expect(controller.activeTarget, isNull);
    expect(controller.activePayload, isNull);
    expect(controller.bouncingToy, isNull);
  });

  for (final change in ['removed', 'content', 'payload', 'species', 'room']) {
    test('pending stimulus is discarded when $change changes', () {
      final controller = PetWorldController()
        ..setMessageBubbleTargets([_message()])
        ..interact('client');
      switch (change) {
        case 'removed':
          controller.setMessageBubbleTargets([]);
          controller.setMessageTargets([
            PetMessageTargetFactory.fromDomainMessage(_message()),
          ]);
        case 'content':
          controller.setMessageBubbleTargets([_message(text: '🎾')]);
        case 'payload':
          controller.setMessageBubbleTargets([_message(text: 'changed')]);
        case 'species':
          controller.setPet(PetType.cat);
          controller.setPet(PetType.corgi);
        case 'room':
          controller.loadRoom(_room);
          controller.setMessageBubbleTargets([_message()]);
      }
      controller.updateObjectBounds({'client': _bounds});
      expect(controller.currentAction, PetActionType.none);
      expect(controller.activeTarget, isNull);
    });
  }

  test('pet change cancels species action and its runtime artifacts', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message(text: '🎾')])
      ..updateObjectBounds({'client': _bounds})
      ..interact('client');
    controller.setPet(PetType.cat);
    expect(controller.currentAction, PetActionType.none);
    expect(controller.state, PetState.idle);
    expect(controller.activeTarget, isNull);
    expect(controller.activePayload, isNull);
    expect(controller.currentPlatform, isNull);
    expect(controller.bouncingToy, isNull);
  });

  test('ignored unready dispatch preserves existing active runtime', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([
        _message(clientId: 'active', text: '🎾'),
        _message(),
      ])
      ..updateObjectBounds({'active': _bounds})
      ..interact('active');
    final active = controller.activeTarget;
    final toy = controller.bouncingToy;
    final position = controller.position;
    expect(
      controller.interact('client').status,
      PetBehaviorExecutionStatus.ignored,
    );
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.chaseEmoji);
    expect(controller.activeTarget, same(active));
    expect(controller.bouncingToy, same(toy));
    expect(controller.activePayload, '🎾');
    expect(controller.position, position);
    controller.tick(const Duration(seconds: 10));
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
  });

  test('executed action clears earlier pending stimulus', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message(), _message(clientId: 'ready')])
      ..interact('client')
      ..updateObjectBounds({'ready': _bounds})
      ..interact('ready')
      ..tick(const Duration(milliseconds: 600));
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
    expect(controller.activeTarget?.id, 'ready');
  });

  test('invalid stimulus never becomes a pending action', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()]);
    final target = PetMessageTarget(
      id: 'client',
      kind: WorldObjectKind.platform,
      contentKind: PetNormalizedContentKind.text,
      payload: 'hello',
      messageText: 'hello',
    );
    controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        target,
        PetStimulusType.loudSound,
        petType: PetType.corgi,
      ),
    );
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
  });

  test('pending retry is consumed after exactly one successful attempt', () {
    final controller = _RecordingController()
      ..setMessageBubbleTargets([_message()]);
    controller.dispatch(
      PetBehaviorNormalizer.fromTarget(
        controller.objects.single,
        PetStimulusType.newMessageBubble,
        petType: PetType.corgi,
      ),
    );
    expect(controller.results.single.reason, 'target bounds are not ready');
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.results, hasLength(2));
    expect(controller.results.last.reason, contains('approach fallback'));
    controller.updateObjectBounds({'client': _bounds});
    controller.updateObjectBounds({'client': _bounds});
    expect(controller.results, hasLength(2));
    expect(controller.currentAction, PetActionType.observeTarget);
    expect(controller.activeTarget?.id, 'client');
  });

  for (final change in ['species', 'content', 'payload']) {
    test('stale $change dispatch preserves active runtime', () {
      final controller = PetWorldController()
        ..setMessageBubbleTargets([_message()]);
      final stale = PetBehaviorNormalizer.fromTarget(
        controller.objects.single,
        PetStimulusType.userTap,
        petType: PetType.corgi,
      );
      if (change == 'species') controller.setPet(PetType.cat);
      controller.setMessageBubbleTargets([
        _message(
          text: switch (change) {
            'content' => '🧶',
            'payload' => 'changed',
            _ => 'hello',
          },
        ),
        _message(clientId: 'active', text: '🎾'),
      ]);
      controller.updateObjectBounds({'client': _bounds, 'active': _bounds});
      controller.interact('active');
      final target = controller.activeTarget;
      final toy = controller.bouncingToy;
      expect(
        controller.dispatch(stale).status,
        PetBehaviorExecutionStatus.ignored,
      );
      expect(controller.activeTarget, same(target));
      expect(controller.bouncingToy, same(toy));
      expect(controller.currentAction, PetActionType.chaseEmoji);
    });
  }

  test('installing and measuring messages never dispatches automatically', () {
    final controller = PetWorldController()
      ..setMessageBubbleTargets([_message()])
      ..updateObjectBounds({'client': _bounds});
    expect(controller.currentAction, PetActionType.none);
    expect(controller.activeTarget, isNull);
  });
}

class _RecordingController extends PetWorldController {
  final results = <PetBehaviorExecutionResult>[];

  @override
  PetBehaviorExecutionResult dispatch(PetBehaviorStimulus stimulus) {
    final result = super.dispatch(stimulus);
    results.add(result);
    return result;
  }
}

domain.ChatMessage _message({
  String clientId = 'client',
  String? serverId,
  String text = 'hello',
  String roomId = 'room',
}) => domain.ChatMessage(
  clientId: clientId,
  serverId: serverId,
  roomId: roomId,
  senderId: 'sender',
  content: MessageContent.text(text: text),
  createdAt: DateTime(2026, 9, 19),
);

const _room = legacy.ChatRoom(
  id: 'legacy-room',
  name: 'Legacy',
  subtitle: '',
  messages: [
    legacy.ChatMessage(
      id: 'legacy',
      sender: 'sender',
      text: 'hello',
      kind: legacy.MessageKind.text,
      isMine: false,
    ),
  ],
);
