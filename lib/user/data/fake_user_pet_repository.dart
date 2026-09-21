import 'dart:async';

import '../../chat/domain/room_member.dart';
import '../../chat/domain/room_summary.dart';
import '../../pet/domain/pet_profile.dart';
import '../../pet/domain/pet_room_snapshot.dart';
import '../domain/user_profile.dart';
import 'user_pet_repository.dart';

class FakeUserPetRepository implements UserPetRepository {
  FakeUserPetRepository({
    this.currentUid = 'me',
    Map<String, UserProfile>? initialUsers,
    Map<String, List<PetProfile>>? initialPets,
    Map<String, List<RoomSummary>>? initialRoomSummaries,
    Map<String, List<RoomMember>>? initialRoomMembers,
  })  : _users = initialUsers ?? {},
        _pets = initialPets ?? {},
        _roomSummaries = initialRoomSummaries ?? {},
        _roomMembers = initialRoomMembers ?? {} {
    if (_users.isEmpty) {
      _seedDefaultData();
    }
  }

  String currentUid;

  final Map<String, UserProfile> _users;
  final Map<String, List<PetProfile>> _pets;
  final Map<String, List<RoomSummary>> _roomSummaries;
  final Map<String, List<RoomMember>> _roomMembers;

  final Map<String, StreamController<UserProfile?>> _userControllers = {};
  final Map<String, StreamController<List<PetProfile>>> _petsControllers = {};
  final Map<String, StreamController<List<RoomSummary>>>
      _roomSummariesControllers = {};
  final Map<String, StreamController<List<RoomMember>>> _roomMembersControllers =
      {};

  void _seedDefaultData() {
    final now = DateTime.now().toUtc();
    const defaultPetId = 'pet_corgi_1';

    final meProfile = UserProfile(
      uid: 'me',
      nickname: '小柴主人',
      avatarUrl: 'assets/avatars/user_me.png',
      searchTag: 'corgi_lover',
      searchTagLower: 'corgi_lover',
      defaultPetId: defaultPetId,
      createdAt: now,
      updatedAt: now,
    );

    final mePets = [
      PetProfile(
        petId: defaultPetId,
        ownerUid: 'me',
        name: '阿福',
        species: PetSpecies.dog,
        breed: 'corgi',
        avatarUrl: 'assets/pets/corgi_real.png',
        gender: PetGender.male,
        personality: 'playful',
        createdAt: now,
        updatedAt: now,
      ),
      PetProfile(
        petId: 'pet_cat_1',
        ownerUid: 'me',
        name: '咪咪',
        species: PetSpecies.cat,
        breed: 'british_shorthair',
        avatarUrl: 'assets/pets/cat_real.png',
        gender: PetGender.female,
        personality: 'curious',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final friendProfile = UserProfile(
      uid: 'user_friend_1',
      nickname: '波波小夥伴',
      avatarUrl: 'assets/avatars/user_friend.png',
      searchTag: 'parrot_fan',
      searchTagLower: 'parrot_fan',
      defaultPetId: 'pet_parrot_1',
      createdAt: now,
      updatedAt: now,
    );

    final friendPets = [
      PetProfile(
        petId: 'pet_parrot_1',
        ownerUid: 'user_friend_1',
        name: '波波',
        species: PetSpecies.parrot,
        breed: 'cockatiel',
        avatarUrl: 'assets/pets/parrot_real.png',
        gender: PetGender.male,
        personality: 'lively',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    _users['me'] = meProfile;
    _users['user_friend_1'] = friendProfile;
    _pets['me'] = mePets;
    _pets['user_friend_1'] = friendPets;

    const defaultRoomId = 'friends';
    _roomSummaries['me'] = [
      RoomSummary(
        roomId: defaultRoomId,
        type: RoomType.direct,
        name: 'Pixel Pals',
        avatarUrl: 'assets/avatars/user_friend.png',
        unreadCount: 0,
        active: true,
        updatedAt: now,
        lastMessageText: '嗨！今天你的寵物夥伴還好嗎？',
        lastMessageSenderId: 'user_friend_1',
        lastMessageAt: now,
      ),
    ];

    _roomMembers[defaultRoomId] = [
      RoomMember(
        uid: 'me',
        role: RoomMemberRole.owner,
        active: true,
        joinedAt: now,
        pets: [PetRoomSnapshot.fromProfile(mePets.first)],
      ),
      RoomMember(
        uid: 'user_friend_1',
        role: RoomMemberRole.member,
        active: true,
        joinedAt: now,
        pets: [PetRoomSnapshot.fromProfile(friendPets.first)],
      ),
    ];
  }

  void _notifyUser(String uid) {
    if (_userControllers.containsKey(uid) &&
        !_userControllers[uid]!.isClosed) {
      _userControllers[uid]!.add(_users[uid]);
    }
  }

  void _notifyPets(String uid) {
    if (_petsControllers.containsKey(uid) &&
        !_petsControllers[uid]!.isClosed) {
      _petsControllers[uid]!.add(List.unmodifiable(_pets[uid] ?? []));
    }
  }

  void _notifyRoomSummaries(String uid) {
    if (_roomSummariesControllers.containsKey(uid) &&
        !_roomSummariesControllers[uid]!.isClosed) {
      _roomSummariesControllers[uid]!
          .add(List.unmodifiable(_roomSummaries[uid] ?? []));
    }
  }

  void _notifyRoomMembers(String roomId) {
    if (_roomMembersControllers.containsKey(roomId) &&
        !_roomMembersControllers[roomId]!.isClosed) {
      _roomMembersControllers[roomId]!
          .add(List.unmodifiable(_roomMembers[roomId] ?? []));
    }
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    return _users[uid];
  }

  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    _userControllers.putIfAbsent(
      uid,
      () => StreamController<UserProfile?>.broadcast(),
    );
    Future.microtask(() => _notifyUser(uid));
    return _userControllers[uid]!.stream;
  }

  @override
  Future<UserProfile> upsertUserProfile({
    required String nickname,
    required String avatarUrl,
    required String searchTag,
  }) async {
    final lower = searchTag.trim().toLowerCase();
    for (final entry in _users.entries) {
      if (entry.key != currentUid && entry.value.searchTagLower == lower) {
        throw StateError('Search tag already exists: $searchTag');
      }
    }

    final existing = _users[currentUid];
    final now = DateTime.now().toUtc();
    final updated = UserProfile(
      uid: currentUid,
      nickname: nickname.trim(),
      avatarUrl: avatarUrl.trim(),
      searchTag: searchTag.trim(),
      searchTagLower: lower,
      defaultPetId: existing?.defaultPetId ?? '',
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    _users[currentUid] = updated;
    _notifyUser(currentUid);
    return updated;
  }

  @override
  Future<List<UserSearchResult>> searchUsers({
    required String query,
    int? limit,
  }) async {
    final clean = query.trim().replaceAll('@', '').toLowerCase();
    final results = <UserSearchResult>[];
    for (final user in _users.values) {
      if (user.uid == currentUid) continue;
      if (user.searchTagLower.contains(clean) ||
          user.nickname.toLowerCase().contains(clean)) {
        results.add(UserSearchResult(
          uid: user.uid,
          nickname: user.nickname,
          avatarUrl: user.avatarUrl,
          defaultPetId:
              user.defaultPetId.isNotEmpty ? user.defaultPetId : null,
        ));
      }
      if (limit != null && results.length >= limit) break;
    }
    return results;
  }

  @override
  Future<List<PetProfile>> getUserPets(String uid) async {
    return List.unmodifiable(_pets[uid] ?? []);
  }

  @override
  Stream<List<PetProfile>> watchUserPets(String uid) {
    _petsControllers.putIfAbsent(
      uid,
      () => StreamController<List<PetProfile>>.broadcast(),
    );
    Future.microtask(() => _notifyPets(uid));
    return _petsControllers[uid]!.stream;
  }

  @override
  Future<PetProfile> registerPet({
    required String name,
    required PetSpecies species,
    required String breed,
    required String avatarUrl,
    PetGender? gender,
    DateTime? birthday,
    String? personality,
    bool? setAsDefault,
  }) async {
    final petId = 'pet_${species.name}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toUtc();
    final newPet = PetProfile(
      petId: petId,
      ownerUid: currentUid,
      name: name.trim(),
      species: species,
      breed: breed.trim(),
      avatarUrl: avatarUrl.trim(),
      gender: gender ?? PetGender.unknown,
      personality: personality?.trim().isNotEmpty == true
          ? personality!.trim()
          : 'playful',
      birthday: birthday,
      createdAt: now,
      updatedAt: now,
    );

    final currentList = _pets[currentUid] ?? [];
    currentList.add(newPet);
    _pets[currentUid] = currentList;

    final user = _users[currentUid];
    if (user != null &&
        (user.defaultPetId.isEmpty || setAsDefault == true)) {
      _users[currentUid] = user.copyWith(defaultPetId: petId);
      _notifyUser(currentUid);
    }

    _notifyPets(currentUid);
    return newPet;
  }

  @override
  Future<PetProfile> updatePet({
    required String petId,
    String? name,
    String? breed,
    String? avatarUrl,
    PetGender? gender,
    DateTime? birthday,
    String? personality,
  }) async {
    final list = _pets[currentUid] ?? [];
    final index = list.indexWhere((p) => p.petId == petId);
    if (index < 0) {
      throw StateError('Pet not found: $petId');
    }

    final existing = list[index];
    final updated = existing.copyWith(
      name: name?.trim() ?? existing.name,
      breed: breed?.trim() ?? existing.breed,
      avatarUrl: avatarUrl?.trim() ?? existing.avatarUrl,
      gender: gender ?? existing.gender,
      birthday: birthday ?? existing.birthday,
      personality: personality?.trim() ?? existing.personality,
      updatedAt: DateTime.now().toUtc(),
    );

    list[index] = updated;
    _pets[currentUid] = list;
    _notifyPets(currentUid);
    return updated;
  }

  @override
  Future<void> setDefaultPet(String petId) async {
    final list = _pets[currentUid] ?? [];
    if (!list.any((p) => p.petId == petId)) {
      throw StateError('Pet does not belong to caller: $petId');
    }
    final user = _users[currentUid];
    if (user != null) {
      _users[currentUid] = user.copyWith(defaultPetId: petId);
      _notifyUser(currentUid);
    }
  }

  @override
  Stream<List<RoomSummary>> watchRoomSummaries(String uid) {
    _roomSummariesControllers.putIfAbsent(
      uid,
      () => StreamController<List<RoomSummary>>.broadcast(),
    );
    Future.microtask(() => _notifyRoomSummaries(uid));
    return _roomSummariesControllers[uid]!.stream;
  }

  @override
  Stream<List<RoomMember>> watchRoomMembers(String roomId) {
    _roomMembersControllers.putIfAbsent(
      roomId,
      () => StreamController<List<RoomMember>>.broadcast(),
    );
    Future.microtask(() => _notifyRoomMembers(roomId));
    return _roomMembersControllers[roomId]!.stream;
  }

  @override
  Future<CreateRoomResult> createRoom({
    required RoomType type,
    required List<String> inviteeUids,
    String? name,
    String? avatarUrl,
  }) async {
    final now = DateTime.now().toUtc();
    String roomId;

    if (type == RoomType.direct) {
      if (inviteeUids.length != 1) {
        throw ArgumentError('Direct room must have exactly 1 invitee');
      }
      final target = inviteeUids.first;
      final sorted = [currentUid, target]..sort();
      roomId = 'dm_${sorted[0]}_${sorted[1]}';
    } else {
      roomId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    }

    final allMemberUids = {currentUid, ...inviteeUids}.toList();
    final membersList = <RoomMember>[];

    for (final memberUid in allMemberUids) {
      final user = _users[memberUid];
      final userPets = _pets[memberUid] ?? [];
      final defaultPet = userPets.firstWhere(
        (p) => p.petId == user?.defaultPetId,
        orElse: () => userPets.isNotEmpty
            ? userPets.first
            : PetProfile(
                petId: 'pet_default_$memberUid',
                ownerUid: memberUid,
                name: '寵物',
                species: PetSpecies.dog,
                breed: 'mix',
                avatarUrl: '',
                createdAt: now,
                updatedAt: now,
              ),
      );

      final role = memberUid == currentUid
          ? RoomMemberRole.owner
          : RoomMemberRole.member;

      membersList.add(RoomMember(
        uid: memberUid,
        role: role,
        active: true,
        joinedAt: now,
        pets: [PetRoomSnapshot.fromProfile(defaultPet)],
      ));

      final summaries = _roomSummaries[memberUid] ?? [];
      final displayName = type == RoomType.direct
          ? (_users[allMemberUids.firstWhere((u) => u != memberUid)]
                  ?.nickname ??
              '對話')
          : (name ?? '群聊');

      summaries.removeWhere((s) => s.roomId == roomId);
      summaries.insert(
        0,
        RoomSummary(
          roomId: roomId,
          type: type,
          name: displayName,
          avatarUrl: avatarUrl,
          unreadCount: 0,
          active: true,
          updatedAt: now,
        ),
      );
      _roomSummaries[memberUid] = summaries;
      _notifyRoomSummaries(memberUid);
    }

    _roomMembers[roomId] = membersList;
    _notifyRoomMembers(roomId);

    return CreateRoomResult(
      roomId: roomId,
      type: type,
      memberCount: allMemberUids.length,
    );
  }

  @override
  Future<List<PetRoomSnapshot>> updateRoomPets({
    required String roomId,
    required List<String> petIds,
  }) async {
    final members = _roomMembers[roomId];
    if (members == null) throw StateError('Room not found: $roomId');

    final memberIndex = members.indexWhere((m) => m.uid == currentUid);
    if (memberIndex < 0) throw StateError('Member not in room');

    final ownedPets = _pets[currentUid] ?? [];
    final selectedSnapshots = <PetRoomSnapshot>[];

    for (final petId in petIds) {
      final pet = ownedPets.firstWhere(
        (p) => p.petId == petId,
        orElse: () => throw StateError('Pet $petId does not belong to caller'),
      );
      selectedSnapshots.add(PetRoomSnapshot.fromProfile(pet));
    }

    members[memberIndex] = members[memberIndex].copyWith(
      pets: selectedSnapshots,
    );
    _roomMembers[roomId] = members;
    _notifyRoomMembers(roomId);

    return selectedSnapshots;
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final members = _roomMembers[roomId];
    if (members != null) {
      final idx = members.indexWhere((m) => m.uid == currentUid);
      if (idx >= 0) {
        members[idx] = members[idx].copyWith(active: false, pets: const []);
        _roomMembers[roomId] = members;
        _notifyRoomMembers(roomId);
      }
    }

    final summaries = _roomSummaries[currentUid];
    if (summaries != null) {
      final sIdx = summaries.indexWhere((s) => s.roomId == roomId);
      if (sIdx >= 0) {
        summaries[sIdx] = summaries[sIdx].copyWith(active: false);
        _roomSummaries[currentUid] = summaries;
        _notifyRoomSummaries(currentUid);
      }
    }
  }

  void dispose() {
    for (final c in _userControllers.values) {
      c.close();
    }
    for (final c in _petsControllers.values) {
      c.close();
    }
    for (final c in _roomSummariesControllers.values) {
      c.close();
    }
    for (final c in _roomMembersControllers.values) {
      c.close();
    }
  }
}
