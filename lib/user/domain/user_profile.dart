import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/domain/datetime_json_converter.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String uid,
    required String nickname,
    required String avatarUrl,
    required String searchTag,
    required String searchTagLower,
    @Default('') String defaultPetId,
    @Default(1) int basePetSlots,
    @Default(0) int invitedBonusSlots,
    @Default(0) int paidBonusSlots,
    @FlexibleDateTimeConverter() required DateTime createdAt,
    @FlexibleDateTimeConverter() required DateTime updatedAt,
  }) = _UserProfile;

  int get maxPetSlots => basePetSlots + invitedBonusSlots + paidBonusSlots;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
