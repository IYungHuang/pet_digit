// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_room_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PetRoomSnapshot _$PetRoomSnapshotFromJson(Map<String, dynamic> json) =>
    _PetRoomSnapshot(
      petId: json['petId'] as String,
      name: json['name'] as String,
      species: $enumDecode(_$PetSpeciesEnumMap, json['species']),
      breed: json['breed'] as String,
      avatarUrl: json['avatarUrl'] as String,
      personality: json['personality'] as String,
    );

Map<String, dynamic> _$PetRoomSnapshotToJson(_PetRoomSnapshot instance) =>
    <String, dynamic>{
      'petId': instance.petId,
      'name': instance.name,
      'species': _$PetSpeciesEnumMap[instance.species]!,
      'breed': instance.breed,
      'avatarUrl': instance.avatarUrl,
      'personality': instance.personality,
    };

const _$PetSpeciesEnumMap = {
  PetSpecies.dog: 'dog',
  PetSpecies.cat: 'cat',
  PetSpecies.parrot: 'parrot',
};
