// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomSummary {

 String get roomId; RoomType get type; String get name; String? get avatarUrl; int get unreadCount; bool get active;@FlexibleDateTimeConverter() DateTime get updatedAt; String? get lastMessageText; String? get lastMessageSenderId;@FlexibleNullableDateTimeConverter() DateTime? get lastMessageAt;
/// Create a copy of RoomSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomSummaryCopyWith<RoomSummary> get copyWith => _$RoomSummaryCopyWithImpl<RoomSummary>(this as RoomSummary, _$identity);

  /// Serializes this RoomSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomSummary&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.active, active) || other.active == active)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastMessageText, lastMessageText) || other.lastMessageText == lastMessageText)&&(identical(other.lastMessageSenderId, lastMessageSenderId) || other.lastMessageSenderId == lastMessageSenderId)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,type,name,avatarUrl,unreadCount,active,updatedAt,lastMessageText,lastMessageSenderId,lastMessageAt);

@override
String toString() {
  return 'RoomSummary(roomId: $roomId, type: $type, name: $name, avatarUrl: $avatarUrl, unreadCount: $unreadCount, active: $active, updatedAt: $updatedAt, lastMessageText: $lastMessageText, lastMessageSenderId: $lastMessageSenderId, lastMessageAt: $lastMessageAt)';
}


}

/// @nodoc
abstract mixin class $RoomSummaryCopyWith<$Res>  {
  factory $RoomSummaryCopyWith(RoomSummary value, $Res Function(RoomSummary) _then) = _$RoomSummaryCopyWithImpl;
@useResult
$Res call({
 String roomId, RoomType type, String name, String? avatarUrl, int unreadCount, bool active,@FlexibleDateTimeConverter() DateTime updatedAt, String? lastMessageText, String? lastMessageSenderId,@FlexibleNullableDateTimeConverter() DateTime? lastMessageAt
});




}
/// @nodoc
class _$RoomSummaryCopyWithImpl<$Res>
    implements $RoomSummaryCopyWith<$Res> {
  _$RoomSummaryCopyWithImpl(this._self, this._then);

  final RoomSummary _self;
  final $Res Function(RoomSummary) _then;

/// Create a copy of RoomSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? type = null,Object? name = null,Object? avatarUrl = freezed,Object? unreadCount = null,Object? active = null,Object? updatedAt = null,Object? lastMessageText = freezed,Object? lastMessageSenderId = freezed,Object? lastMessageAt = freezed,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RoomType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastMessageText: freezed == lastMessageText ? _self.lastMessageText : lastMessageText // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSenderId: freezed == lastMessageSenderId ? _self.lastMessageSenderId : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomSummary].
extension RoomSummaryPatterns on RoomSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomSummary value)  $default,){
final _that = this;
switch (_that) {
case _RoomSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomSummary value)?  $default,){
final _that = this;
switch (_that) {
case _RoomSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  RoomType type,  String name,  String? avatarUrl,  int unreadCount,  bool active, @FlexibleDateTimeConverter()  DateTime updatedAt,  String? lastMessageText,  String? lastMessageSenderId, @FlexibleNullableDateTimeConverter()  DateTime? lastMessageAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomSummary() when $default != null:
return $default(_that.roomId,_that.type,_that.name,_that.avatarUrl,_that.unreadCount,_that.active,_that.updatedAt,_that.lastMessageText,_that.lastMessageSenderId,_that.lastMessageAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  RoomType type,  String name,  String? avatarUrl,  int unreadCount,  bool active, @FlexibleDateTimeConverter()  DateTime updatedAt,  String? lastMessageText,  String? lastMessageSenderId, @FlexibleNullableDateTimeConverter()  DateTime? lastMessageAt)  $default,) {final _that = this;
switch (_that) {
case _RoomSummary():
return $default(_that.roomId,_that.type,_that.name,_that.avatarUrl,_that.unreadCount,_that.active,_that.updatedAt,_that.lastMessageText,_that.lastMessageSenderId,_that.lastMessageAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  RoomType type,  String name,  String? avatarUrl,  int unreadCount,  bool active, @FlexibleDateTimeConverter()  DateTime updatedAt,  String? lastMessageText,  String? lastMessageSenderId, @FlexibleNullableDateTimeConverter()  DateTime? lastMessageAt)?  $default,) {final _that = this;
switch (_that) {
case _RoomSummary() when $default != null:
return $default(_that.roomId,_that.type,_that.name,_that.avatarUrl,_that.unreadCount,_that.active,_that.updatedAt,_that.lastMessageText,_that.lastMessageSenderId,_that.lastMessageAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomSummary implements RoomSummary {
  const _RoomSummary({required this.roomId, required this.type, required this.name, this.avatarUrl, this.unreadCount = 0, this.active = true, @FlexibleDateTimeConverter() required this.updatedAt, this.lastMessageText, this.lastMessageSenderId, @FlexibleNullableDateTimeConverter() this.lastMessageAt});
  factory _RoomSummary.fromJson(Map<String, dynamic> json) => _$RoomSummaryFromJson(json);

@override final  String roomId;
@override final  RoomType type;
@override final  String name;
@override final  String? avatarUrl;
@override@JsonKey() final  int unreadCount;
@override@JsonKey() final  bool active;
@override@FlexibleDateTimeConverter() final  DateTime updatedAt;
@override final  String? lastMessageText;
@override final  String? lastMessageSenderId;
@override@FlexibleNullableDateTimeConverter() final  DateTime? lastMessageAt;

/// Create a copy of RoomSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomSummaryCopyWith<_RoomSummary> get copyWith => __$RoomSummaryCopyWithImpl<_RoomSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomSummary&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.active, active) || other.active == active)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastMessageText, lastMessageText) || other.lastMessageText == lastMessageText)&&(identical(other.lastMessageSenderId, lastMessageSenderId) || other.lastMessageSenderId == lastMessageSenderId)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,type,name,avatarUrl,unreadCount,active,updatedAt,lastMessageText,lastMessageSenderId,lastMessageAt);

@override
String toString() {
  return 'RoomSummary(roomId: $roomId, type: $type, name: $name, avatarUrl: $avatarUrl, unreadCount: $unreadCount, active: $active, updatedAt: $updatedAt, lastMessageText: $lastMessageText, lastMessageSenderId: $lastMessageSenderId, lastMessageAt: $lastMessageAt)';
}


}

/// @nodoc
abstract mixin class _$RoomSummaryCopyWith<$Res> implements $RoomSummaryCopyWith<$Res> {
  factory _$RoomSummaryCopyWith(_RoomSummary value, $Res Function(_RoomSummary) _then) = __$RoomSummaryCopyWithImpl;
@override @useResult
$Res call({
 String roomId, RoomType type, String name, String? avatarUrl, int unreadCount, bool active,@FlexibleDateTimeConverter() DateTime updatedAt, String? lastMessageText, String? lastMessageSenderId,@FlexibleNullableDateTimeConverter() DateTime? lastMessageAt
});




}
/// @nodoc
class __$RoomSummaryCopyWithImpl<$Res>
    implements _$RoomSummaryCopyWith<$Res> {
  __$RoomSummaryCopyWithImpl(this._self, this._then);

  final _RoomSummary _self;
  final $Res Function(_RoomSummary) _then;

/// Create a copy of RoomSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? type = null,Object? name = null,Object? avatarUrl = freezed,Object? unreadCount = null,Object? active = null,Object? updatedAt = null,Object? lastMessageText = freezed,Object? lastMessageSenderId = freezed,Object? lastMessageAt = freezed,}) {
  return _then(_RoomSummary(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RoomType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastMessageText: freezed == lastMessageText ? _self.lastMessageText : lastMessageText // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSenderId: freezed == lastMessageSenderId ? _self.lastMessageSenderId : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
