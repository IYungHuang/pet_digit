import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/user/data/fake_user_pet_repository.dart';
import 'package:chat_pet_mvp/user/presentation/user_pet_providers.dart';
import 'package:chat_pet_mvp/user/presentation/widgets/room_members_dialog.dart';

void main() {
  group('RoomMembersDialog Widget Tests', () {
    late FakeUserPetRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeUserPetRepository(currentUid: 'me');
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    testWidgets('renders room members, shows 10-person capacity banner, and copies link',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPetRepositoryProvider.overrideWithValue(fakeRepo),
            fakeUserPetRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => RoomMembersDialog.show(
                  context,
                  roomId: 'friends',
                  roomName: 'Pixel Pals',
                  onOpenRoom: (_) {},
                ),
                child: const Text('Open Room Members'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Room Members'));
      await tester.pumpAndSettle();

      // Check header and room name
      expect(find.text('Pixel Pals'), findsOneWidget);
      expect(find.text('群組成員與出戰寵物管理（上限 10 人）'), findsOneWidget);

      // Check capacity banner
      expect(find.text('👥 群組成員容納量'), findsOneWidget);
      expect(find.text('2 / 10 人 (MVP 上限)'), findsOneWidget);
      expect(find.text('✨ 還可以邀請 8 位好友加入共同冒險！'), findsOneWidget);

      // Check bottom action buttons
      expect(find.text('複製群組連結'), findsOneWidget);
      expect(find.text('邀請好友進群'), findsOneWidget);

      // Tap copy link
      await tester.tap(find.text('複製群組連結'));
      await tester.pumpAndSettle();

      expect(find.text('群組邀請連結已複製！可透過 LINE / 簡訊分享給好友'), findsOneWidget);
    });
  });
}
