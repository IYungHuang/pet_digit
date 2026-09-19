import '../message_data_sources.dart';
import '../../domain/message_draft.dart';

class FakeMessageRemoteDataSource implements MessageRemoteDataSource {
  FakeMessageRemoteDataSource({this.latency = Duration.zero});

  final Duration latency;
  bool failNextSend = false;
  int sendCount = 0;
  int _nextServerId = 1;

  @override
  Future<RemoteMessageReceipt> send(MessageDraft draft) async {
    sendCount++;
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failNextSend) {
      failNextSend = false;
      throw StateError('fake send failed');
    }

    return RemoteMessageReceipt(
      serverId: 'server-${_nextServerId++}',
      serverCreatedAt: DateTime.now().toUtc(),
    );
  }
}
