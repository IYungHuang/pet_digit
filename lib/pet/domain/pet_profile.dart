import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/domain/datetime_json_converter.dart';
import 'pet_world.dart';

part 'pet_profile.freezed.dart';
part 'pet_profile.g.dart';

enum PetSpecies {
  @JsonValue('dog')
  dog,
  @JsonValue('cat')
  cat,
  @JsonValue('parrot')
  parrot,
}

extension PetSpeciesX on PetSpecies {
  PetType toPetType() {
    return switch (this) {
      PetSpecies.dog => PetType.corgi,
      PetSpecies.cat => PetType.cat,
      PetSpecies.parrot => PetType.parrot,
    };
  }
}

enum PetGender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('neutered')
  neutered,
  @JsonValue('unknown')
  unknown,
}

@freezed
abstract class PetProfile with _$PetProfile {
  const factory PetProfile({
    required String petId,
    required String ownerUid,
    required String name,
    required PetSpecies species,
    required String breed,
    required String avatarUrl,
    @Default([]) List<String> photoUrls,
    @Default(PetGender.unknown) PetGender gender,
    @Default('playful') String personality,
    @FlexibleNullableDateTimeConverter() DateTime? birthday,
    @FlexibleDateTimeConverter() required DateTime createdAt,
    @FlexibleDateTimeConverter() required DateTime updatedAt,
  }) = _PetProfile;

  factory PetProfile.fromJson(Map<String, dynamic> json) =>
      _$PetProfileFromJson(json);
}
