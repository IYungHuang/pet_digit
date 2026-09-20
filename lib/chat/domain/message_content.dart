import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_content.freezed.dart';
part 'message_content.g.dart';

@freezed
sealed class MessageContent with _$MessageContent {
  const factory MessageContent.text({required String text}) =
      TextMessageContent;

  const factory MessageContent.image({
    required String url,
    required String mimeType,
    String? localPath,
  }) = ImageMessageContent;

  const factory MessageContent.video({
    required String url,
    required String mimeType,
    String? localPath,
    String? thumbnailUrl,
    int? durationMs,
  }) = VideoMessageContent;

  factory MessageContent.fromJson(Map<String, dynamic> json) =>
      _$MessageContentFromJson(json);
}
