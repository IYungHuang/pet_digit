import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/domain/datetime_json_converter.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String nickname,
    required String avatarUrl,
    required String searchTag,
    required String searchTagLower,
    @Default('') String defaultPetId,
    @FlexibleDateTimeConverter() required DateTime createdAt,
    @FlexibleDateTimeConverter() required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
