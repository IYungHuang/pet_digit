// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MessageDraft {

 String get clientId; String get roomId; String get senderId; MessageContent get content; DateTime get createdAt; bool get isMine;
/// Create a copy of MessageDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageDraftCopyWith<MessageDraft> get copyWith => _$MessageDraftCopyWithImpl<MessageDraft>(this as MessageDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageDraft&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isMine, isMine) || other.isMine == isMine));
}


@override
int get hashCode => Object.hash(runtimeType,clientId,roomId,senderId,content,createdAt,isMine);

@override
String toString() {
  return 'MessageDraft(clientId: $clientId, roomId: $roomId, senderId: $senderId, content: $content, createdAt: $createdAt, isMine: $isMine)';
}


}

/// @nodoc
abstract mixin class $MessageDraftCopyWith<$Res>  {
  factory $MessageDraftCopyWith(MessageDraft value, $Res Function(MessageDraft) _then) = _$MessageDraftCopyWithImpl;
@useResult
$Res call({
 String clientId, String roomId, String senderId, MessageContent content, DateTime createdAt, bool isMine
});


$MessageContentCopyWith<$Res> get content;

}
/// @nodoc
class _$MessageDraftCopyWithImpl<$Res>
    implements $MessageDraftCopyWith<$Res> {
  _$MessageDraftCopyWithImpl(this._self, this._then);

  final MessageDraft _self;
  final $Res Function(MessageDraft) _then;

/// Create a copy of MessageDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? roomId = null,Object? senderId = null,Object? content = null,Object? createdAt = null,Object? isMine = null,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as MessageContent,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of MessageDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageContentCopyWith<$Res> get content {
  
  return $MessageContentCopyWith<$Res>(_self.content, (value) {
    return _then(_self.copyWith(content: value));
  });
}
}


/// Adds pattern-matching-related methods to [MessageDraft].
extension MessageDraftPatterns on MessageDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageDraft value)  $default,){
final _that = this;
switch (_that) {
case _MessageDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageDraft value)?  $default,){
final _that = this;
switch (_that) {
case _MessageDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String roomId,  String senderId,  MessageContent content,  DateTime createdAt,  bool isMine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageDraft() when $default != null:
return $default(_that.clientId,_that.roomId,_that.senderId,_that.content,_that.createdAt,_that.isMine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String roomId,  String senderId,  MessageContent content,  DateTime createdAt,  bool isMine)  $default,) {final _that = this;
switch (_that) {
case _MessageDraft():
return $default(_that.clientId,_that.roomId,_that.senderId,_that.content,_that.createdAt,_that.isMine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String roomId,  String senderId,  MessageContent content,  DateTime createdAt,  bool isMine)?  $default,) {final _that = this;
switch (_that) {
case _MessageDraft() when $default != null:
return $default(_that.clientId,_that.roomId,_that.senderId,_that.content,_that.createdAt,_that.isMine);case _:
  return null;

}
}

}

/// @nodoc


class _MessageDraft implements MessageDraft {
  const _MessageDraft({required this.clientId, required this.roomId, required this.senderId, required this.content, required this.createdAt, this.isMine = false});
  

@override final  String clientId;
@override final  String roomId;
@override final  String senderId;
@override final  MessageContent content;
@override final  DateTime createdAt;
@override@JsonKey() final  bool isMine;

/// Create a copy of MessageDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageDraftCopyWith<_MessageDraft> get copyWith => __$MessageDraftCopyWithImpl<_MessageDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageDraft&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isMine, isMine) || other.isMine == isMine));
}


@override
int get hashCode => Object.hash(runtimeType,clientId,roomId,senderId,content,createdAt,isMine);

@override
String toString() {
  return 'MessageDraft(clientId: $clientId, roomId: $roomId, senderId: $senderId, content: $content, createdAt: $createdAt, isMine: $isMine)';
}


}

/// @nodoc
abstract mixin class _$MessageDraftCopyWith<$Res> implements $MessageDraftCopyWith<$Res> {
  factory _$MessageDraftCopyWith(_MessageDraft value, $Res Function(_MessageDraft) _then) = __$MessageDraftCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String roomId, String senderId, MessageContent content, DateTime createdAt, bool isMine
});


@override $MessageContentCopyWith<$Res> get content;

}
/// @nodoc
class __$MessageDraftCopyWithImpl<$Res>
    implements _$MessageDraftCopyWith<$Res> {
  __$MessageDraftCopyWithImpl(this._self, this._then);

  final _MessageDraft _self;
  final $Res Function(_MessageDraft) _then;

/// Create a copy of MessageDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? roomId = null,Object? senderId = null,Object? content = null,Object? createdAt = null,Object? isMine = null,}) {
  return _then(_MessageDraft(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as MessageContent,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of MessageDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageContentCopyWith<$Res> get content {
  
  return $MessageContentCopyWith<$Res>(_self.content, (value) {
    return _then(_self.copyWith(content: value));
  });
}
}

// dart format on
