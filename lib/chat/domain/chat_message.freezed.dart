// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessage {

 String get clientId; String? get serverId; String get roomId; String get senderId; MessageContent get content; MessageDeliveryStatus get status; DateTime get createdAt; DateTime? get serverCreatedAt; double get uploadProgress; String? get error; bool get isMine;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.serverCreatedAt, serverCreatedAt) || other.serverCreatedAt == serverCreatedAt)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.error, error) || other.error == error)&&(identical(other.isMine, isMine) || other.isMine == isMine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serverId,roomId,senderId,content,status,createdAt,serverCreatedAt,uploadProgress,error,isMine);

@override
String toString() {
  return 'ChatMessage(clientId: $clientId, serverId: $serverId, roomId: $roomId, senderId: $senderId, content: $content, status: $status, createdAt: $createdAt, serverCreatedAt: $serverCreatedAt, uploadProgress: $uploadProgress, error: $error, isMine: $isMine)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String clientId, String? serverId, String roomId, String senderId, MessageContent content, MessageDeliveryStatus status, DateTime createdAt, DateTime? serverCreatedAt, double uploadProgress, String? error, bool isMine
});


$MessageContentCopyWith<$Res> get content;

}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? serverId = freezed,Object? roomId = null,Object? senderId = null,Object? content = null,Object? status = null,Object? createdAt = null,Object? serverCreatedAt = freezed,Object? uploadProgress = null,Object? error = freezed,Object? isMine = null,}) {
  return _then(_self.copyWith(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String?,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as MessageContent,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageDeliveryStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,serverCreatedAt: freezed == serverCreatedAt ? _self.serverCreatedAt : serverCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageContentCopyWith<$Res> get content {
  
  return $MessageContentCopyWith<$Res>(_self.content, (value) {
    return _then(_self.copyWith(content: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  String? serverId,  String roomId,  String senderId,  MessageContent content,  MessageDeliveryStatus status,  DateTime createdAt,  DateTime? serverCreatedAt,  double uploadProgress,  String? error,  bool isMine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.clientId,_that.serverId,_that.roomId,_that.senderId,_that.content,_that.status,_that.createdAt,_that.serverCreatedAt,_that.uploadProgress,_that.error,_that.isMine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  String? serverId,  String roomId,  String senderId,  MessageContent content,  MessageDeliveryStatus status,  DateTime createdAt,  DateTime? serverCreatedAt,  double uploadProgress,  String? error,  bool isMine)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.clientId,_that.serverId,_that.roomId,_that.senderId,_that.content,_that.status,_that.createdAt,_that.serverCreatedAt,_that.uploadProgress,_that.error,_that.isMine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  String? serverId,  String roomId,  String senderId,  MessageContent content,  MessageDeliveryStatus status,  DateTime createdAt,  DateTime? serverCreatedAt,  double uploadProgress,  String? error,  bool isMine)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.clientId,_that.serverId,_that.roomId,_that.senderId,_that.content,_that.status,_that.createdAt,_that.serverCreatedAt,_that.uploadProgress,_that.error,_that.isMine);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.clientId, this.serverId, required this.roomId, required this.senderId, required this.content, this.status = MessageDeliveryStatus.pending, required this.createdAt, this.serverCreatedAt, this.uploadProgress = 0, this.error, this.isMine = false});
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String clientId;
@override final  String? serverId;
@override final  String roomId;
@override final  String senderId;
@override final  MessageContent content;
@override@JsonKey() final  MessageDeliveryStatus status;
@override final  DateTime createdAt;
@override final  DateTime? serverCreatedAt;
@override@JsonKey() final  double uploadProgress;
@override final  String? error;
@override@JsonKey() final  bool isMine;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.serverId, serverId) || other.serverId == serverId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.content, content) || other.content == content)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.serverCreatedAt, serverCreatedAt) || other.serverCreatedAt == serverCreatedAt)&&(identical(other.uploadProgress, uploadProgress) || other.uploadProgress == uploadProgress)&&(identical(other.error, error) || other.error == error)&&(identical(other.isMine, isMine) || other.isMine == isMine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,clientId,serverId,roomId,senderId,content,status,createdAt,serverCreatedAt,uploadProgress,error,isMine);

@override
String toString() {
  return 'ChatMessage(clientId: $clientId, serverId: $serverId, roomId: $roomId, senderId: $senderId, content: $content, status: $status, createdAt: $createdAt, serverCreatedAt: $serverCreatedAt, uploadProgress: $uploadProgress, error: $error, isMine: $isMine)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String clientId, String? serverId, String roomId, String senderId, MessageContent content, MessageDeliveryStatus status, DateTime createdAt, DateTime? serverCreatedAt, double uploadProgress, String? error, bool isMine
});


@override $MessageContentCopyWith<$Res> get content;

}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? serverId = freezed,Object? roomId = null,Object? senderId = null,Object? content = null,Object? status = null,Object? createdAt = null,Object? serverCreatedAt = freezed,Object? uploadProgress = null,Object? error = freezed,Object? isMine = null,}) {
  return _then(_ChatMessage(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String?,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as MessageContent,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MessageDeliveryStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,serverCreatedAt: freezed == serverCreatedAt ? _self.serverCreatedAt : serverCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,uploadProgress: null == uploadProgress ? _self.uploadProgress : uploadProgress // ignore: cast_nullable_to_non_nullable
as double,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ChatMessage
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
