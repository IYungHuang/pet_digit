import '../message_data_sources.dart';
import '../../domain/message_content.dart';
import '../../domain/message_draft.dart';

class FakeMediaUploadDataSource implements MediaUploadDataSource {
  FakeMediaUploadDataSource({this.latency = Duration.zero});

  final Duration latency;

  @override
  Future<MessageContent> upload(
    MessageDraft draft, {
    void Function(double progress)? onProgress,
  }) async {
    const progressSteps = <double>[0.25, 0.5, 0.75, 1.0];
    for (final progress in progressSteps) {
      if (latency > Duration.zero) await Future<void>.delayed(latency);
      onProgress?.call(progress);
    }

    final fakeUrl = 'fake://media/${draft.clientId}';
    return switch (draft.content) {
      ImageMessageContent value => value.copyWith(url: fakeUrl),
      VideoMessageContent value => value.copyWith(url: fakeUrl),
      TextMessageContent() => throw StateError('text does not require upload'),
    };
  }
}
