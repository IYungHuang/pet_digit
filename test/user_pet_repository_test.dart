import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/chat/domain/room_member.dart';
import 'package:chat_pet_mvp/chat/domain/room_summary.dart';
import 'package:chat_pet_mvp/pet/domain/pet_profile.dart';
import 'package:chat_pet_mvp/pet/domain/pet_room_snapshot.dart';
import 'package:chat_pet_mvp/user/domain/user_profile.dart';
import 'package:chat_pet_mvp/user/data/fake_user_pet_repository.dart';

void main() {
  group('Domain Models Serialization', () {
    test('UserProfile json serialization roundtrip', () {
      final now = DateTime.utc(2026, 9, 21, 10, 0, 0);
      final profile = UserProfile(
        uid: 'user_123',
        nickname: '柴柴阿呆',
        avatarUrl: 'https://example.com/avatar.png',
        searchTag: 'shiba_dai',
        searchTagLower: 'shiba_dai',
        defaultPetId: 'pet_dog_1',
        createdAt: now,
        updatedAt: now,
      );

      final json = profile.toJson();
      final decoded = UserProfile.fromJson(json);

      expect(decoded.uid, 'user_123');
      expect(decoded.nickname, '柴柴阿呆');
      expect(decoded.searchTag, 'shiba_dai');
      expect(decoded.defaultPetId, 'pet_dog_1');
      expect(decoded.createdAt, now);
    });

    test('PetProfile json serialization roundtrip', () {
      final now = DateTime.utc(2026, 9, 21, 10, 0, 0);
      final pet = PetProfile(
        petId: 'pet_999',
        ownerUid: 'user_123',
        name: '波比',
        species: PetSpecies.dog,
        breed: 'corgi',
        avatarUrl: 'https://example.com/corgi.png',
        gender: PetGender.male,
        personality: 'energetic',
        birthday: DateTime.utc(2023, 5, 1),
        createdAt: now,
        updatedAt: now,
      );

      final json = pet.toJson();
      final decoded = PetProfile.fromJson(json);

      expect(decoded.petId, 'pet_999');
      expect(decoded.name, '波比');
      expect(decoded.species, PetSpecies.dog);
      expect(decoded.gender, PetGender.male);
      expect(decoded.birthday, DateTime.utc(2023, 5, 1));
    });

    test('PetRoomSnapshot from PetProfile', () {
      final now = DateTime.utc(2026, 9, 21, 10, 0, 0);
      final pet = PetProfile(
        petId: 'pet_cat_8',
        ownerUid: 'user_456',
        name: '咪咪',
        species: PetSpecies.cat,
        breed: 'persian',
        avatarUrl: 'https://example.com/cat.png',
        gender: PetGender.female,
        personality: 'calm',
        createdAt: now,
        updatedAt: now,
      );

      final snapshot = PetRoomSnapshot.fromProfile(pet);
      expect(snapshot.petId, 'pet_cat_8');
      expect(snapshot.name, '咪咪');
      expect(snapshot.species, PetSpecies.cat);
      expect(snapshot.personality, 'calm');
    });

    test('RoomSummary serialization roundtrip', () {
      final now = DateTime.utc(2026, 9, 21, 10, 0, 0);
      final summary = RoomSummary(
        roomId: 'dm_user1_user2',
        type: RoomType.direct,
        name: '好友對話',
        unreadCount: 3,
        active: true,
        updatedAt: now,
        lastMessageText: '晚上帶狗狗出門嗎？',
        lastMessageSenderId: 'user2',
        lastMessageAt: now,
      );

      final json = summary.toJson();
      final decoded = RoomSummary.fromJson(json);

      expect(decoded.roomId, 'dm_user1_user2');
      expect(decoded.type, RoomType.direct);
      expect(decoded.unreadCount, 3);
      expect(decoded.lastMessageText, '晚上帶狗狗出門嗎？');
    });

    test('RoomMember serialization roundtrip', () {
      final now = DateTime.utc(2026, 9, 21, 10, 0, 0);
      final member = RoomMember(
        uid: 'user_xyz',
        role: RoomMemberRole.owner,
        active: true,
        joinedAt: now,
        pets: const [
          PetRoomSnapshot(
            petId: 'pet_1',
            name: '阿福',
            species: PetSpecies.dog,
            breed: 'corgi',
            avatarUrl: '',
            personality: 'playful',
          ),
        ],
      );

      final json = member.toJson();
      final decoded = RoomMember.fromJson(json);

      expect(decoded.uid, 'user_xyz');
      expect(decoded.role, RoomMemberRole.owner);
      expect(decoded.active, isTrue);
      expect(decoded.pets.length, 1);
      expect(decoded.pets.first.name, '阿福');
    });
  });

  group('FakeUserPetRepository', () {
    late FakeUserPetRepository repo;

    setUp(() {
      repo = FakeUserPetRepository(currentUid: 'me');
    });

    tearDown(() {
      repo.dispose();
    });

    test('seed data is present on initialize', () async {
      final profile = await repo.getUserProfile('me');
      expect(profile, isNotNull);
      expect(profile!.nickname, '小柴主人');
      expect(profile.defaultPetId, 'pet_corgi_1');

      final pets = await repo.getUserPets('me');
      expect(pets.length, 2);
      expect(pets[0].name, '阿福');
      expect(pets[1].name, '咪咪');
    });

    test('upsertUserProfile updates profile and enforces unique searchTag',
        () async {
      final updated = await repo.upsertUserProfile(
        nickname: '新主人暱稱',
        avatarUrl: 'https://example.com/new_avatar.png',
        searchTag: 'unique_tag_123',
      );

      expect(updated.nickname, '新主人暱稱');
      expect(updated.searchTag, 'unique_tag_123');

      // Attempt duplicate tag by another user
      repo.currentUid = 'other_user';
      expect(
        () => repo.upsertUserProfile(
          nickname: '另一個人',
          avatarUrl: '',
          searchTag: 'unique_tag_123',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('searchUsers finds users by nickname or tag', () async {
      final results = await repo.searchUsers(query: 'parrot');
      expect(results.length, 1);
      expect(results.first.uid, 'user_friend_1');
      expect(results.first.nickname, '波波小夥伴');
    });

    test('registerPet adds pet and updates defaultPetId if empty', () async {
      repo.currentUid = 'brand_new_user';
      // First upsert profile with empty defaultPetId
      await repo.upsertUserProfile(
        nickname: '新用戶',
        avatarUrl: '',
        searchTag: 'brand_new',
      );

      final newPet = await repo.registerPet(
        name: '玄鳳波比',
        species: PetSpecies.parrot,
        breed: 'cockatiel',
        avatarUrl: 'https://example.com/parrot.png',
        personality: 'lively',
      );

      expect(newPet.name, '玄鳳波比');
      expect(newPet.species, PetSpecies.parrot);

      final user = await repo.getUserProfile('brand_new_user');
      expect(user!.defaultPetId, newPet.petId);

      final pets = await repo.getUserPets('brand_new_user');
      expect(pets.length, 1);
      expect(pets.first.petId, newPet.petId);
    });

    test('updatePet and setDefaultPet', () async {
      final updatedPet = await repo.updatePet(
        petId: 'pet_corgi_1',
        name: '超級阿福',
        personality: 'very_playful',
      );

      expect(updatedPet.name, '超級阿福');
      expect(updatedPet.personality, 'very_playful');

      await repo.setDefaultPet('pet_cat_1');
      final user = await repo.getUserProfile('me');
      expect(user!.defaultPetId, 'pet_cat_1');
    });

    test('createRoom direct message and group message', () async {
      // Direct room
      final dmResult = await repo.createRoom(
        type: RoomType.direct,
        inviteeUids: ['user_friend_1'],
      );
      expect(dmResult.roomId, 'dm_me_user_friend_1');
      expect(dmResult.memberCount, 2);

      // Group room
      final groupResult = await repo.createRoom(
        type: RoomType.group,
        inviteeUids: ['user_friend_1'],
        name: '毛孩同樂會',
      );
      expect(groupResult.roomId.startsWith('group_'), isTrue);
      expect(groupResult.memberCount, 2);
    });

    test('updateRoomPets updates active pets in room', () async {
      const roomId = 'friends';
      final updated = await repo.updateRoomPets(
        roomId: roomId,
        petIds: ['pet_corgi_1', 'pet_cat_1'],
      );

      expect(updated.length, 2);
      expect(updated[0].name, '阿福');
      expect(updated[1].name, '咪咪');
    });

    test('leaveRoom marks active false and empties room pets', () async {
      const roomId = 'friends';
      await repo.leaveRoom(roomId);

      final summariesStream = repo.watchRoomSummaries('me');
      final summaries = await summariesStream.first;
      final roomSummary = summaries.firstWhere((s) => s.roomId == roomId);
      expect(roomSummary.active, isFalse);
    });
  });
}
