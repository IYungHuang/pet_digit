// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  clientId: json['clientId'] as String,
  serverId: json['serverId'] as String?,
  roomId: json['roomId'] as String,
  senderId: json['senderId'] as String,
  content: MessageContent.fromJson(json['content'] as Map<String, dynamic>),
  status:
      $enumDecodeNullable(_$MessageDeliveryStatusEnumMap, json['status']) ??
      MessageDeliveryStatus.pending,
  createdAt: DateTime.parse(json['createdAt'] as String),
  serverCreatedAt: json['serverCreatedAt'] == null
      ? null
      : DateTime.parse(json['serverCreatedAt'] as String),
  uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0,
  error: json['error'] as String?,
  isMine: json['isMine'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'serverId': instance.serverId,
      'roomId': instance.roomId,
      'senderId': instance.senderId,
      'content': instance.content,
      'status': _$MessageDeliveryStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'serverCreatedAt': instance.serverCreatedAt?.toIso8601String(),
      'uploadProgress': instance.uploadProgress,
      'error': instance.error,
      'isMine': instance.isMine,
    };

const _$MessageDeliveryStatusEnumMap = {
  MessageDeliveryStatus.pending: 'pending',
  MessageDeliveryStatus.uploading: 'uploading',
  MessageDeliveryStatus.sending: 'sending',
  MessageDeliveryStatus.sent: 'sent',
  MessageDeliveryStatus.failed: 'failed',
};
