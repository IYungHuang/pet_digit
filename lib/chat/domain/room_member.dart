import 'package:freezed_annotation/freezed_annotation.dart';

import '../../common/domain/datetime_json_converter.dart';
import '../../pet/domain/pet_room_snapshot.dart';

part 'room_member.freezed.dart';
part 'room_member.g.dart';

enum RoomMemberRole {
  @JsonValue('owner')
  owner,
  @JsonValue('admin')
  admin,
  @JsonValue('member')
  member,
}

List<Map<String, dynamic>> _petsToJson(List<PetRoomSnapshot> pets) =>
    pets.map((p) => p.toJson()).toList();

@freezed
abstract class RoomMember with _$RoomMember {
  const factory RoomMember({
    required String uid,
    required RoomMemberRole role,
    @Default(true) bool active,
    @FlexibleDateTimeConverter() required DateTime joinedAt,
    @JsonKey(toJson: _petsToJson)
    @Default(<PetRoomSnapshot>[])
    List<PetRoomSnapshot> pets,
  }) = _RoomMember;

  factory RoomMember.fromJson(Map<String, dynamic> json) =>
      _$RoomMemberFromJson(json);
}
