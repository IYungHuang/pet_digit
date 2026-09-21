import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/user/data/fake_user_pet_repository.dart';
import 'package:chat_pet_mvp/user/data/phone_contacts_service.dart';

void main() {
  group('PhoneContactsService Tests', () {
    late FakeUserPetRepository fakeRepo;
    late PhoneContactsService service;

    setUp(() {
      fakeRepo = FakeUserPetRepository(currentUid: 'me');
      service = PhoneContactsService();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    test('getLocalContacts returns mock contacts', () async {
      final contacts = await service.getLocalContacts();
      expect(contacts.length, greaterThanOrEqualTo(5));
      expect(contacts.any((c) => c.name.contains('王大明')), isTrue);
    });

    test('syncAndMatch identifies registered vs unregistered contacts', () async {
      final synced = await service.syncAndMatch(repository: fakeRepo);

      // 王大明 (波波夥伴) should match registered user_friend_1
      final boboFriend = synced.firstWhere((c) => c.name.contains('王大明'));
      expect(boboFriend.isRegistered, isTrue);
      expect(boboFriend.registeredUid, 'user_friend_1');
      expect(boboFriend.isFriend, isTrue);

      // 李經理 should be unregistered
      final manager = synced.firstWhere((c) => c.name.contains('李經理'));
      expect(manager.isRegistered, isFalse);
      expect(manager.isFriend, isFalse);
    });

    test('buildSmsInviteText formats friendly text with web url and code', () {
      final text = PhoneContactsService.buildSmsInviteText(
        contactName: '大衛',
        myInviteCode: 'PET999',
      );

      expect(text, contains('大衛'));
      expect(text, contains('https://pet-digit-chat.web.app/join'));
      expect(text, contains('PET999'));
    });
  });
}
