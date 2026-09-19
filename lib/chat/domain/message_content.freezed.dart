// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
MessageContent _$MessageContentFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'text':
          return TextMessageContent.fromJson(
            json
          );
                case 'image':
          return ImageMessageContent.fromJson(
            json
          );
                case 'video':
          return VideoMessageContent.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'MessageContent',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$MessageContent {



  /// Serializes this MessageContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageContent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MessageContent()';
}


}

/// @nodoc
class $MessageContentCopyWith<$Res>  {
$MessageContentCopyWith(MessageContent _, $Res Function(MessageContent) __);
}


/// Adds pattern-matching-related methods to [MessageContent].
extension MessageContentPatterns on MessageContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextMessageContent value)?  text,TResult Function( ImageMessageContent value)?  image,TResult Function( VideoMessageContent value)?  video,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextMessageContent() when text != null:
return text(_that);case ImageMessageContent() when image != null:
return image(_that);case VideoMessageContent() when video != null:
return video(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextMessageContent value)  text,required TResult Function( ImageMessageContent value)  image,required TResult Function( VideoMessageContent value)  video,}){
final _that = this;
switch (_that) {
case TextMessageContent():
return text(_that);case ImageMessageContent():
return image(_that);case VideoMessageContent():
return video(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextMessageContent value)?  text,TResult? Function( ImageMessageContent value)?  image,TResult? Function( VideoMessageContent value)?  video,}){
final _that = this;
switch (_that) {
case TextMessageContent() when text != null:
return text(_that);case ImageMessageContent() when image != null:
return image(_that);case VideoMessageContent() when video != null:
return video(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  text,TResult Function( String url,  String mimeType,  String? localPath)?  image,TResult Function( String url,  String mimeType,  String? localPath,  String? thumbnailUrl,  int? durationMs)?  video,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextMessageContent() when text != null:
return text(_that.text);case ImageMessageContent() when image != null:
return image(_that.url,_that.mimeType,_that.localPath);case VideoMessageContent() when video != null:
return video(_that.url,_that.mimeType,_that.localPath,_that.thumbnailUrl,_that.durationMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  text,required TResult Function( String url,  String mimeType,  String? localPath)  image,required TResult Function( String url,  String mimeType,  String? localPath,  String? thumbnailUrl,  int? durationMs)  video,}) {final _that = this;
switch (_that) {
case TextMessageContent():
return text(_that.text);case ImageMessageContent():
return image(_that.url,_that.mimeType,_that.localPath);case VideoMessageContent():
return video(_that.url,_that.mimeType,_that.localPath,_that.thumbnailUrl,_that.durationMs);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  text,TResult? Function( String url,  String mimeType,  String? localPath)?  image,TResult? Function( String url,  String mimeType,  String? localPath,  String? thumbnailUrl,  int? durationMs)?  video,}) {final _that = this;
switch (_that) {
case TextMessageContent() when text != null:
return text(_that.text);case ImageMessageContent() when image != null:
return image(_that.url,_that.mimeType,_that.localPath);case VideoMessageContent() when video != null:
return video(_that.url,_that.mimeType,_that.localPath,_that.thumbnailUrl,_that.durationMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TextMessageContent implements MessageContent {
  const TextMessageContent({required this.text, final  String? $type}): $type = $type ?? 'text';
  factory TextMessageContent.fromJson(Map<String, dynamic> json) => _$TextMessageContentFromJson(json);

 final  String text;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextMessageContentCopyWith<TextMessageContent> get copyWith => _$TextMessageContentCopyWithImpl<TextMessageContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TextMessageContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextMessageContent&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'MessageContent.text(text: $text)';
}


}

/// @nodoc
abstract mixin class $TextMessageContentCopyWith<$Res> implements $MessageContentCopyWith<$Res> {
  factory $TextMessageContentCopyWith(TextMessageContent value, $Res Function(TextMessageContent) _then) = _$TextMessageContentCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$TextMessageContentCopyWithImpl<$Res>
    implements $TextMessageContentCopyWith<$Res> {
  _$TextMessageContentCopyWithImpl(this._self, this._then);

  final TextMessageContent _self;
  final $Res Function(TextMessageContent) _then;

/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(TextMessageContent(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ImageMessageContent implements MessageContent {
  const ImageMessageContent({required this.url, required this.mimeType, this.localPath, final  String? $type}): $type = $type ?? 'image';
  factory ImageMessageContent.fromJson(Map<String, dynamic> json) => _$ImageMessageContentFromJson(json);

 final  String url;
 final  String mimeType;
 final  String? localPath;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageMessageContentCopyWith<ImageMessageContent> get copyWith => _$ImageMessageContentCopyWithImpl<ImageMessageContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImageMessageContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageMessageContent&&(identical(other.url, url) || other.url == url)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.localPath, localPath) || other.localPath == localPath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,mimeType,localPath);

@override
String toString() {
  return 'MessageContent.image(url: $url, mimeType: $mimeType, localPath: $localPath)';
}


}

/// @nodoc
abstract mixin class $ImageMessageContentCopyWith<$Res> implements $MessageContentCopyWith<$Res> {
  factory $ImageMessageContentCopyWith(ImageMessageContent value, $Res Function(ImageMessageContent) _then) = _$ImageMessageContentCopyWithImpl;
@useResult
$Res call({
 String url, String mimeType, String? localPath
});




}
/// @nodoc
class _$ImageMessageContentCopyWithImpl<$Res>
    implements $ImageMessageContentCopyWith<$Res> {
  _$ImageMessageContentCopyWithImpl(this._self, this._then);

  final ImageMessageContent _self;
  final $Res Function(ImageMessageContent) _then;

/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,Object? mimeType = null,Object? localPath = freezed,}) {
  return _then(ImageMessageContent(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class VideoMessageContent implements MessageContent {
  const VideoMessageContent({required this.url, required this.mimeType, this.localPath, this.thumbnailUrl, this.durationMs, final  String? $type}): $type = $type ?? 'video';
  factory VideoMessageContent.fromJson(Map<String, dynamic> json) => _$VideoMessageContentFromJson(json);

 final  String url;
 final  String mimeType;
 final  String? localPath;
 final  String? thumbnailUrl;
 final  int? durationMs;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoMessageContentCopyWith<VideoMessageContent> get copyWith => _$VideoMessageContentCopyWithImpl<VideoMessageContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoMessageContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoMessageContent&&(identical(other.url, url) || other.url == url)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,mimeType,localPath,thumbnailUrl,durationMs);

@override
String toString() {
  return 'MessageContent.video(url: $url, mimeType: $mimeType, localPath: $localPath, thumbnailUrl: $thumbnailUrl, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $VideoMessageContentCopyWith<$Res> implements $MessageContentCopyWith<$Res> {
  factory $VideoMessageContentCopyWith(VideoMessageContent value, $Res Function(VideoMessageContent) _then) = _$VideoMessageContentCopyWithImpl;
@useResult
$Res call({
 String url, String mimeType, String? localPath, String? thumbnailUrl, int? durationMs
});




}
/// @nodoc
class _$VideoMessageContentCopyWithImpl<$Res>
    implements $VideoMessageContentCopyWith<$Res> {
  _$VideoMessageContentCopyWithImpl(this._self, this._then);

  final VideoMessageContent _self;
  final $Res Function(VideoMessageContent) _then;

/// Create a copy of MessageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,Object? mimeType = null,Object? localPath = freezed,Object? thumbnailUrl = freezed,Object? durationMs = freezed,}) {
  return _then(VideoMessageContent(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
