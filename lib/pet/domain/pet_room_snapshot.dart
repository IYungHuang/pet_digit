import 'package:freezed_annotation/freezed_annotation.dart';

import 'pet_profile.dart';

part 'pet_room_snapshot.freezed.dart';
part 'pet_room_snapshot.g.dart';

@freezed
abstract class PetRoomSnapshot with _$PetRoomSnapshot {
  const factory PetRoomSnapshot({
    required String petId,
    required String name,
    required PetSpecies species,
    required String breed,
    required String avatarUrl,
    required String personality,
  }) = _PetRoomSnapshot;

  factory PetRoomSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PetRoomSnapshotFromJson(json);

  factory PetRoomSnapshot.fromProfile(PetProfile profile) => PetRoomSnapshot(
        petId: profile.petId,
        name: profile.name,
        species: profile.species,
        breed: profile.breed,
        avatarUrl: profile.avatarUrl,
        personality: profile.personality,
      );
}
