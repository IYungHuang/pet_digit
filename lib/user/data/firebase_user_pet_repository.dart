import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../chat/domain/room_member.dart';
import '../../chat/domain/room_summary.dart';
import '../../pet/domain/pet_profile.dart';
import '../../pet/domain/pet_room_snapshot.dart';
import '../domain/user_profile.dart';
import 'user_pet_repository.dart';

class FirebaseUserPetRepository implements UserPetRepository {
  FirebaseUserPetRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return <String, dynamic>{};
  }

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromJson(doc.data()!);
  }

  @override
  Stream<UserProfile?> watchUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromJson(doc.data()!);
    });
  }

  @override
  Future<UserProfile> upsertUserProfile({
    required String nickname,
    required String avatarUrl,
    required String searchTag,
  }) async {
    final result = await _functions.httpsCallable('upsertUserProfile').call({
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'searchTag': searchTag,
    });
    final map = _toMap(result.data);
    return UserProfile.fromJson(map);
  }

  @override
  Future<List<UserSearchResult>> searchUsers({
    required String query,
    int? limit,
  }) async {
    final result = await _functions.httpsCallable('searchUsers').call({
      'query': query,
      if (limit != null) 'limit': limit,
    });
    final list = (result.data as List<dynamic>?) ?? [];
    return list
        .map((item) => UserSearchResult.fromJson(_toMap(item)))
        .toList();
  }

  @override
  Future<List<PetProfile>> getUserPets(String uid) async {
    final snapshot =
        await _firestore.collection('users').doc(uid).collection('pets').get();
    return snapshot.docs.map((doc) => PetProfile.fromJson(doc.data())).toList();
  }

  @override
  Stream<List<PetProfile>> watchUserPets(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('pets')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PetProfile.fromJson(doc.data())).toList());
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
    final result = await _functions.httpsCallable('registerPet').call({
      'name': name,
      'species': species.name,
      'breed': breed,
      'avatarUrl': avatarUrl,
      if (gender != null) 'gender': gender.name,
      if (birthday != null) 'birthday': birthday.toUtc().toIso8601String(),
      if (personality != null) 'personality': personality,
      if (setAsDefault != null) 'setAsDefault': setAsDefault,
    });
    final map = _toMap(result.data);
    return PetProfile.fromJson(map);
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
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (breed != null) updates['breed'] = breed;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (gender != null) updates['gender'] = gender.name;
    if (birthday != null) {
      updates['birthday'] = birthday.toUtc().toIso8601String();
    }
    if (personality != null) updates['personality'] = personality;

    final result = await _functions.httpsCallable('updatePet').call({
      'petId': petId,
      'updates': updates,
    });
    final map = _toMap(result.data);
    return PetProfile.fromJson(map);
  }

  @override
  Future<void> setDefaultPet(String petId) async {
    await _functions.httpsCallable('setDefaultPet').call({
      'petId': petId,
    });
  }

  @override
  Stream<List<RoomSummary>> watchRoomSummaries(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('roomSummaries')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomSummary.fromJson(doc.data()))
            .toList());
  }

  @override
  Stream<List<RoomMember>> watchRoomMembers(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RoomMember.fromJson(doc.data()))
            .toList());
  }

  @override
  Future<CreateRoomResult> createRoom({
    required RoomType type,
    required List<String> inviteeUids,
    String? name,
    String? avatarUrl,
  }) async {
    final result = await _functions.httpsCallable('createRoom').call({
      'type': type.name,
      'inviteeUids': inviteeUids,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    final map = _toMap(result.data);
    return CreateRoomResult.fromJson(map);
  }

  @override
  Future<List<PetRoomSnapshot>> updateRoomPets({
    required String roomId,
    required List<String> petIds,
  }) async {
    final result = await _functions.httpsCallable('updateRoomPets').call({
      'roomId': roomId,
      'petIds': petIds,
    });
    final map = _toMap(result.data);
    final activePets = (map['activePets'] as List<dynamic>?) ?? [];
    return activePets
        .map((item) => PetRoomSnapshot.fromJson(_toMap(item)))
        .toList();
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    await _functions.httpsCallable('leaveRoom').call({
      'roomId': roomId,
    });
  }
}
