import '../../chat/domain/room_member.dart';
import '../../chat/domain/room_summary.dart';
import '../../pet/domain/pet_profile.dart';
import '../../pet/domain/pet_room_snapshot.dart';
import '../domain/user_profile.dart';

class UserSearchResult {
  const UserSearchResult({
    required this.uid,
    required this.nickname,
    required this.avatarUrl,
    this.defaultPetId,
  });

  final String uid;
  final String nickname;
  final String avatarUrl;
  final String? defaultPetId;

  factory UserSearchResult.fromJson(Map<String, dynamic> json) =>
      UserSearchResult(
        uid: json['uid'] as String,
        nickname: json['nickname'] as String,
        avatarUrl: json['avatarUrl'] as String,
        defaultPetId: json['defaultPetId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        if (defaultPetId != null) 'defaultPetId': defaultPetId,
      };
}

class CreateRoomResult {
  const CreateRoomResult({
    required this.roomId,
    required this.type,
    required this.memberCount,
  });

  final String roomId;
  final RoomType type;
  final int memberCount;

  factory CreateRoomResult.fromJson(Map<String, dynamic> json) =>
      CreateRoomResult(
        roomId: json['roomId'] as String,
        type: json['type'] == 'group' ? RoomType.group : RoomType.direct,
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 1,
      );
}

abstract class UserPetRepository {
  // User Profile
  Future<UserProfile?> getUserProfile(String uid);
  Stream<UserProfile?> watchUserProfile(String uid);
  Future<UserProfile> upsertUserProfile({
    required String nickname,
    required String avatarUrl,
    required String searchTag,
  });
  Future<List<UserSearchResult>> searchUsers({
    required String query,
    int? limit,
  });
  Future<void> addFriend(String targetUid);
  Future<bool> isFriend(String targetUid);

  // Pets
  Future<List<PetProfile>> getUserPets(String uid);
  Stream<List<PetProfile>> watchUserPets(String uid);
  Future<PetProfile> registerPet({
    required String name,
    required PetSpecies species,
    required String breed,
    required String avatarUrl,
    PetGender? gender,
    DateTime? birthday,
    String? personality,
    bool? setAsDefault,
  });
  Future<PetProfile> updatePet({
    required String petId,
    String? name,
    String? breed,
    String? avatarUrl,
    PetGender? gender,
    DateTime? birthday,
    String? personality,
  });
  Future<void> setDefaultPet(String petId);

  // Rooms & Multi-Pet Summoning
  Stream<List<RoomSummary>> watchRoomSummaries(String uid);
  Stream<List<RoomMember>> watchRoomMembers(String roomId);
  Future<CreateRoomResult> createRoom({
    required RoomType type,
    required List<String> inviteeUids,
    String? name,
    String? avatarUrl,
  });
  Future<List<PetRoomSnapshot>> updateRoomPets({
    required String roomId,
    required List<String> petIds,
  });
  Future<void> leaveRoom(String roomId);
}
