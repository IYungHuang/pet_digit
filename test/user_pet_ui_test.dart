import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/user/data/fake_user_pet_repository.dart';
import 'package:chat_pet_mvp/user/presentation/user_pet_providers.dart';
import 'package:chat_pet_mvp/user/presentation/screens/auth_screen.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/create_room_dialog.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/my_pets_backpack_dialog.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/onboarding_wizard_dialog.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/pet_edit_dialog.dart';
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
      await tester.tap(find.text('下一步：登記寵物 ➔'));
      await tester.pumpAndSettle();
      expect(find.text('請輸入主人暱稱'), findsOneWidget);

      // Fill in valid nickname and tag
      await tester.enterText(find.byType(TextField).first, '帥氣主人');
      await tester.enterText(find.byType(TextField).at(1), 'cool_owner');
      await tester.tap(find.text('下一步：登記寵物 ➔'));
      await tester.pumpAndSettle();

      // Should now be on Step 2
      expect(find.text('登記第一隻寵物夥伴'), findsOneWidget);
      expect(find.text('寵物名字'), findsOneWidget);
    });

    testWidgets('skips pet binding and completes onboarding directly with later button',
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

      await tester.enterText(find.byType(TextField).first, '獨立主人');
      await tester.enterText(find.byType(TextField).at(1), 'solo_owner');
      await tester.tap(find.text('下一步：登記寵物 ➔'));
      await tester.pumpAndSettle();

      // Tap later button
      final laterButton = find.text('稍後再綁定 (先去逛逛)');
      expect(laterButton, findsOneWidget);
      await tester.ensureVisible(laterButton);
      await tester.tap(laterButton);
      await tester.pumpAndSettle();

      // Wizard dialog should be dismissed
      expect(find.text('登記第一隻寵物夥伴'), findsNothing);

      final user = await fakeRepo.getUserProfile('me');
      expect(user?.nickname, '獨立主人');
      expect(user?.searchTag, 'solo_owner');
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

      expect(find.text('我的寵物背包'), findsOneWidget);
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

      expect(find.text('房間寵物出動調度'), findsOneWidget);
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

  group('PetEditDialog Widget Tests', () {
    testWidgets('edits pet name and personality and saves successfully',
        (tester) async {
      final pets = await fakeRepo.getUserPets('me');
      final firstPet = pets.first;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => PetEditDialog.show(context, pet: firstPet),
              child: const Text('Open Edit Pet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Pet'));
      await tester.pumpAndSettle();

      expect(find.text('編輯寵物資料 - ${firstPet.name}'), findsOneWidget);
      expect(find.text('寵物名字'), findsOneWidget);

      // Modify name
      await tester.enterText(find.widgetWithText(TextField, firstPet.name), '超級阿福');
      await tester.pumpAndSettle();

      // Tap personality chip
      await tester.tap(find.text('好奇寶寶 🔍'));
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('儲存更新'));
      await tester.pumpAndSettle();

      // Verify update in repo
      final updatedPets = await fakeRepo.getUserPets('me');
      final updated = updatedPets.firstWhere((p) => p.petId == firstPet.petId);
      expect(updated.name, '超級阿福');
      expect(updated.personality, 'curious');
    });
  });

  group('AuthScreen Widget Tests', () {
    testWidgets('renders social buttons and registers new user', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const AuthScreen()),
      );

      expect(find.text('Pixel Pals 冒險入口'), findsOneWidget);
      expect(find.text('Google 帳號'), findsOneWidget);
      expect(find.text('Apple 帳號'), findsOneWidget);
      expect(find.text('立即登記首隻寵物夥伴 (可選)'), findsOneWidget);

      // Fill in registration
      await tester.enterText(find.byType(TextField).first, '冒險家小智');
      await tester.enterText(find.byType(TextField).at(1), 'trainer_ash');
      await tester.pumpAndSettle();

      // Register without pet
      final submitButton = find.text('完成身分登記，直接進入 🚀');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final user = await fakeRepo.getUserProfile('me');
      expect(user?.nickname, '冒險家小智');
      expect(user?.searchTag, 'trainer_ash');
    });

    testWidgets('connects Google account and displays pet adoption flow',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(const AuthScreen()),
      );

      // Tap Google account button
      await tester.tap(find.text('Google 帳號'));
      await tester.pumpAndSettle();

      expect(find.text('Google 帳號已成功連結 ✔'), findsOneWidget);
      expect(find.text('🎉 歡迎踏入數位寵物世界！'), findsOneWidget);
      expect(find.text('📸 上傳現實寵物生活照'), findsOneWidget);
      expect(find.text('選取生活照'), findsOneWidget);

      // Enter pet name and adopt
      await tester.enterText(
          find.widgetWithText(TextField, '替牠取個名字（如：旺財、波波）'), '皮卡');
      final adoptButton = find.text('🐾 馬上領養寵物夥伴並進入');
      await tester.ensureVisible(adoptButton);
      await tester.tap(adoptButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final pets = await fakeRepo.getUserPets('me');
      expect(pets.any((p) => p.name == '皮卡'), isTrue);
    });

    testWidgets(
        'preset pet photo chips display correct breeds and update breed input',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(const AuthScreen()),
      );

      // Tap Google account button
      await tester.tap(find.text('Google 帳號'));
      await tester.pumpAndSettle();

      // Dog presets by default:
      expect(find.text('柯基寫真'), findsOneWidget);
      expect(find.text('柴犬寫真'), findsOneWidget);

      // Tap 柯基寫真
      await tester.tap(find.text('柯基寫真'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '柯基犬'), findsOneWidget);

      // Switch to cat
      await tester.tap(find.text('🐱 貓咪'));
      await tester.pumpAndSettle();

      // Cat presets:
      expect(find.text('布偶寫真'), findsOneWidget);
      expect(find.text('英短寫真'), findsOneWidget);

      // Tap 布偶寫真
      await tester.tap(find.text('布偶寫真'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '布偶貓'), findsOneWidget);

      // Tap 英短寫真
      await tester.tap(find.text('英短寫真'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '英國短毛貓'), findsOneWidget);
    });
  });
}
