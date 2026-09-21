import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/user/data/fake_user_pet_repository.dart';
import 'package:chat_pet_mvp/user/presentation/user_pet_providers.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/contacts_dialog.dart';

void main() {
  group('ContactsDialog Widget Tests', () {
    late FakeUserPetRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeUserPetRepository(currentUid: 'me');
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    testWidgets('renders tabs, loads seeded friends, and can switch to invite tab', (tester) async {
      String? openedRoomId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPetRepositoryProvider.overrideWithValue(fakeRepo),
            fakeUserPetRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ContactsDialog.show(
                  context,
                  onOpenRoom: (id) => openedRoomId = id,
                ),
                child: const Text('Open Contacts'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Contacts'));
      await tester.pumpAndSettle();

      // Check dialog header and tabs
      expect(find.text('通訊錄與好友'), findsOneWidget);
      expect(find.text('👥 好友名單'), findsOneWidget);
      expect(find.text('🔍 搜尋加好友'), findsOneWidget);
      expect(find.text('🎟️ 邀請碼 / 連結'), findsOneWidget);

      // Friends tab is active: should find seeded friend '波波小夥伴'
      expect(find.text('波波小夥伴'), findsOneWidget);
      expect(find.text('🟢 在線'), findsOneWidget);
      expect(find.text('💬 私聊'), findsOneWidget);

      // Tap 💬 私聊
      await tester.tap(find.text('💬 私聊'));
      await tester.pumpAndSettle();

      // Should have opened 1v1 room between me and user_friend_1
      expect(openedRoomId, isNotNull);
      expect(openedRoomId, contains('dm_'));
    });

    testWidgets('can enter invite code in Invite Tab', (tester) async {
      String? openedRoomId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPetRepositoryProvider.overrideWithValue(fakeRepo),
            fakeUserPetRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ContactsDialog.show(
                  context,
                  onOpenRoom: (id) => openedRoomId = id,
                ),
                child: const Text('Open Contacts'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Contacts'));
      await tester.pumpAndSettle();

      // Switch to Invite Tab
      await tester.tap(find.text('🎟️ 邀請碼 / 連結'));
      await tester.pumpAndSettle();

      expect(find.text('輸入群組邀請碼或 Deeplink'), findsOneWidget);
      expect(find.text('複製我的專屬邀請連結'), findsOneWidget);

      // Enter code
      await tester.enterText(
        find.widgetWithText(TextField, '例：PET9AB 或 petdigit://...'),
        'PET123',
      );
      await tester.tap(find.text('加入群組'));
      await tester.pumpAndSettle();

      expect(openedRoomId, 'group_pet123');
    });

    testWidgets('renders Phone Contacts tab and displays matched contacts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPetRepositoryProvider.overrideWithValue(fakeRepo),
            fakeUserPetRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ContactsDialog.show(
                  context,
                  onOpenRoom: (_) {},
                ),
                child: const Text('Open Contacts'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Contacts'));
      await tester.pumpAndSettle();

      // Check phone contacts tab
      expect(find.text('📱 手機通訊錄'), findsOneWidget);
      await tester.tap(find.text('📱 手機通訊錄'));
      await tester.pumpAndSettle();

      // Should find header and seeded contact
      expect(find.text('已自動比對手機通訊錄'), findsOneWidget);
      expect(find.text('王大明 (波波夥伴)'), findsOneWidget);
      expect(find.text('陳阿福 (柴犬阿福爸)'), findsOneWidget);
      expect(find.text('加好友'), findsWidgets);

      // Scroll to find unregistered contact
      await tester.scrollUntilVisible(
        find.text('李經理'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('李經理'), findsOneWidget);
      expect(find.text('邀請'), findsWidgets);
    });
  });
}
