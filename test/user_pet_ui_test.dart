import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/user/data/fake_user_pet_repository.dart';
import 'package:chat_pet_mvp/user/presentation/user_pet_providers.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/create_room_dialog.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/my_pets_backpack_dialog.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/onboarding_wizard_dialog.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/room_pet_summon_dialog.dart';

void main() {
  late FakeUserPetRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeUserPetRepository(currentUid: 'me');
  });

  tearDown(() {
    fakeRepo.dispose();
  });

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      overrides: [
        userPetRepositoryProvider.overrideWithValue(fakeRepo),
        fakeUserPetRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('OnboardingWizardDialog Widget Tests', () {
    testWidgets('shows step 1 and advances to step 2 on valid input',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => OnboardingWizardDialog.show(context),
              child: const Text('Open Wizard'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Wizard'));
      await tester.pumpAndSettle();

      expect(find.text('設定主人身份'), findsOneWidget);
      expect(find.text('主人暱稱'), findsOneWidget);

      // Attempt next step with empty input -> validation error
      await tester.tap(find.text('下一步：登記毛孩 ➔'));
      await tester.pumpAndSettle();
      expect(find.text('請輸入主人暱稱'), findsOneWidget);

      // Fill in valid nickname and tag
      await tester.enterText(find.byType(TextField).first, '帥氣主人');
      await tester.enterText(find.byType(TextField).at(1), 'cool_owner');
      await tester.tap(find.text('下一步：登記毛孩 ➔'));
      await tester.pumpAndSettle();

      // Should now be on Step 2
      expect(find.text('登記第一隻毛孩'), findsOneWidget);
      expect(find.text('毛孩名字'), findsOneWidget);
    });
  });

  group('MyPetsBackpackDialog Widget Tests', () {
    testWidgets('displays owned pets and default badge', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MyPetsBackpackDialog.show(context),
              child: const Text('Open Backpack'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Backpack'));
      await tester.pumpAndSettle();

      expect(find.text('我的毛孩背包'), findsOneWidget);
      expect(find.text('阿福'), findsOneWidget);
      expect(find.text('咪咪'), findsOneWidget);
      expect(find.text('⭐ 預設主寵'), findsOneWidget);

      // Switch default pet to 咪咪
      final setDefaultBtn = find.text('設為主寵');
      expect(setDefaultBtn, findsOneWidget);
      await tester.tap(setDefaultBtn);
      await tester.pumpAndSettle();

      final updatedProfile = await fakeRepo.getUserProfile('me');
      expect(updatedProfile!.defaultPetId, 'pet_cat_1');
    });
  });

  group('RoomPetSummonDialog Widget Tests', () {
    testWidgets('toggles pet selection for room', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  RoomPetSummonDialog.show(context, roomId: 'friends'),
              child: const Text('Open Summon'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Summon'));
      await tester.pumpAndSettle();

      expect(find.text('房間毛孩出動調度'), findsOneWidget);
      expect(find.text('阿福'), findsOneWidget);
      expect(find.text('咪咪'), findsOneWidget);

      // Select second pet
      final checkBoxes = find.byType(Checkbox);
      expect(checkBoxes, findsNWidgets(2));

      await tester.tap(checkBoxes.last);
      await tester.pumpAndSettle();

      // Tap confirm button
      await tester.tap(find.text('確定出動 (2 隻)'));
      await tester.pumpAndSettle();

      final members = await fakeRepo.watchRoomMembers('friends').first;
      final myMember = members.firstWhere((m) => m.uid == 'me');
      expect(myMember.pets.length, 2);
    });
  });

  group('CreateRoomDialog Widget Tests', () {
    testWidgets('searches user and creates 1v1 direct room', (tester) async {
      String? createdRoomId;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => CreateRoomDialog.show(
                context,
                onRoomCreated: (id) => createdRoomId = id,
              ),
              child: const Text('Open Create Room'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Create Room'));
      await tester.pumpAndSettle();

      expect(find.text('發起新對話'), findsOneWidget);
      expect(find.text('波波小夥伴'), findsOneWidget);

      // Tap start chat with user_friend_1
      await tester.tap(find.text('發起對話'));
      await tester.pumpAndSettle();

      expect(createdRoomId, 'dm_me_user_friend_1');
    });
  });
}
