// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  uid: json['uid'] as String,
  nickname: json['nickname'] as String,
  avatarUrl: json['avatarUrl'] as String,
  searchTag: json['searchTag'] as String,
  searchTagLower: json['searchTagLower'] as String,
  defaultPetId: json['defaultPetId'] as String? ?? '',
  basePetSlots: (json['basePetSlots'] as num?)?.toInt() ?? 1,
  invitedBonusSlots: (json['invitedBonusSlots'] as num?)?.toInt() ?? 0,
  paidBonusSlots: (json['paidBonusSlots'] as num?)?.toInt() ?? 0,
  createdAt: const FlexibleDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FlexibleDateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'nickname': instance.nickname,
      'avatarUrl': instance.avatarUrl,
      'searchTag': instance.searchTag,
      'searchTagLower': instance.searchTagLower,
      'defaultPetId': instance.defaultPetId,
      'basePetSlots': instance.basePetSlots,
      'invitedBonusSlots': instance.invitedBonusSlots,
      'paidBonusSlots': instance.paidBonusSlots,
      'createdAt': const FlexibleDateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const FlexibleDateTimeConverter().toJson(instance.updatedAt),
    };
