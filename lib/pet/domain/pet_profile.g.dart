// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PetProfile _$PetProfileFromJson(Map<String, dynamic> json) => _PetProfile(
  petId: json['petId'] as String,
  ownerUid: json['ownerUid'] as String,
  name: json['name'] as String,
  species: $enumDecode(_$PetSpeciesEnumMap, json['species']),
  breed: json['breed'] as String,
  avatarUrl: json['avatarUrl'] as String,
  photoUrls:
      (json['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  gender:
      $enumDecodeNullable(_$PetGenderEnumMap, json['gender']) ??
      PetGender.unknown,
  personality: json['personality'] as String? ?? 'playful',
  birthday: const FlexibleNullableDateTimeConverter().fromJson(
    json['birthday'],
  ),
  createdAt: const FlexibleDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FlexibleDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$PetProfileToJson(_PetProfile instance) =>
    <String, dynamic>{
      'petId': instance.petId,
      'ownerUid': instance.ownerUid,
      'name': instance.name,
      'species': _$PetSpeciesEnumMap[instance.species]!,
      'breed': instance.breed,
      'avatarUrl': instance.avatarUrl,
      'photoUrls': instance.photoUrls,
      'gender': _$PetGenderEnumMap[instance.gender]!,
      'personality': instance.personality,
      'birthday': const FlexibleNullableDateTimeConverter().toJson(
        instance.birthday,
      ),
      'createdAt': const FlexibleDateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const FlexibleDateTimeConverter().toJson(instance.updatedAt),
    };

const _$PetSpeciesEnumMap = {
  PetSpecies.dog: 'dog',
  PetSpecies.cat: 'cat',
  PetSpecies.parrot: 'parrot',
};

const _$PetGenderEnumMap = {
  PetGender.male: 'male',
  PetGender.female: 'female',
  PetGender.neutered: 'neutered',
  PetGender.unknown: 'unknown',
};
