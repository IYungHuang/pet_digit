import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/pet/domain/actions/pet_action_context.dart';
import 'package:chat_pet_mvp/pet/domain/actions/pet_action_handler.dart';
import 'package:chat_pet_mvp/pet/domain/pet_action_plan.dart';
import 'package:chat_pet_mvp/pet/domain/pet_action_runner.dart';

void main() {
  group('PetActionRunner handler registry', () {
    test('default registry creates a fresh handler for every action', () {
      final runner = PetActionRunner();

      for (final action in PetRuntimeAction.values) {
        final first = runner.createHandler(action);
        final second = runner.createHandler(action);

        expect(first.action, action);
        expect(second.action, action);
        expect(second, isNot(same(first)), reason: action.name);
      }
    });

    test('constructor rejects a registry missing an action', () {
      final entries = PetRuntimeAction.values
          .skip(1)
          .map((action) => MapEntry(action, () => _Handler(action)));

      expect(
        () => PetActionRunner(handlerFactories: entries),
        throwsArgumentError,
      );
    });

    test('constructor rejects duplicate action factories', () {
      final entries = [
        ...PetRuntimeAction.values.map(
          (action) => MapEntry(action, () => _Handler(action)),
        ),
        MapEntry(
          PetRuntimeAction.observeTarget,
          () => _Handler(PetRuntimeAction.observeTarget),
        ),
      ];

      expect(
        () => PetActionRunner(handlerFactories: entries),
        throwsArgumentError,
      );
    });
  });
}

class _Handler implements PetActionHandler {
  _Handler(this.action);

  @override
  final PetRuntimeAction action;

  @override
  void cancel(PetActionContext context, PetActionEndReason reason) {}

  @override
  void start(PetActionContext context, PetActionPlan plan) {}

  @override
  PetActionTickResult tick(PetActionContext context, Duration elapsed) =>
      PetActionTickResult.running;
}
