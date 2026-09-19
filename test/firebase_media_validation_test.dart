import 'package:flutter_test/flutter_test.dart';

import 'package:chat_pet_mvp/chat/data/firebase/firebase_media_upload_data_source.dart';

void main() {
  test('accepts backend MIME allowlist and rejects unsupported MIME', () {
    expect(FirebaseMediaUploadDataSource.isSupportedMime('image/jpeg'), isTrue);
    expect(
      FirebaseMediaUploadDataSource.isSupportedMime('video/quicktime'),
      isTrue,
    );
    expect(
      FirebaseMediaUploadDataSource.isSupportedMime('application/pdf'),
      isFalse,
    );
  });

  test('validates staging path identity', () {
    expect(
      FirebaseMediaUploadDataSource.isValidStagingPath(
        'rooms/room-1/media/user-1/client-1/original',
        roomId: 'room-1',
        uid: 'user-1',
        clientId: 'client-1',
      ),
      isTrue,
    );
    expect(
      FirebaseMediaUploadDataSource.isValidStagingPath(
        'rooms/room-1/media/other-user/client-1/original',
        roomId: 'room-1',
        uid: 'user-1',
        clientId: 'client-1',
      ),
      isFalse,
    );
  });
}
