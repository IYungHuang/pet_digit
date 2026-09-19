// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextMessageContent _$TextMessageContentFromJson(Map<String, dynamic> json) =>
    TextMessageContent(
      text: json['text'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$TextMessageContentToJson(TextMessageContent instance) =>
    <String, dynamic>{'text': instance.text, 'runtimeType': instance.$type};

ImageMessageContent _$ImageMessageContentFromJson(Map<String, dynamic> json) =>
    ImageMessageContent(
      url: json['url'] as String,
      mimeType: json['mimeType'] as String,
      localPath: json['localPath'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$ImageMessageContentToJson(
  ImageMessageContent instance,
) => <String, dynamic>{
  'url': instance.url,
  'mimeType': instance.mimeType,
  'localPath': instance.localPath,
  'runtimeType': instance.$type,
};

VideoMessageContent _$VideoMessageContentFromJson(Map<String, dynamic> json) =>
    VideoMessageContent(
      url: json['url'] as String,
      mimeType: json['mimeType'] as String,
      localPath: json['localPath'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$VideoMessageContentToJson(
  VideoMessageContent instance,
) => <String, dynamic>{
  'url': instance.url,
  'mimeType': instance.mimeType,
  'localPath': instance.localPath,
  'thumbnailUrl': instance.thumbnailUrl,
  'durationMs': instance.durationMs,
  'runtimeType': instance.$type,
};
