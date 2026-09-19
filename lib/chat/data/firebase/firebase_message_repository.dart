import '../../data/fake/fake_message_repository.dart';
import 'firebase_message_event_source.dart';

/// Firebase transport using same repository state machine as fake transport.
/// This preserves optimistic merge, retry state, and clientId dedupe seam.
class FirebaseMessageRepository extends FakeMessageRepository {
  FirebaseMessageRepository({
    required super.remote,
    required super.upload,
    required FirebaseMessageEventSource events,
  }) : super(events: events);
}
