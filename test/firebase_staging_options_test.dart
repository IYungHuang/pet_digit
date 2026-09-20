import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/firebase/firebase_options_staging.dart';

void main() {
  test('staging Apple options target registered Firebase app', () {
    const options = StagingFirebaseOptions.apple;
    expect(options.projectId, 'pet-digit-backend');
    expect(options.appId, '1:473616221902:ios:5613d495e3d6f07c3a729f');
    expect(options.messagingSenderId, '473616221902');
    expect(options.storageBucket, 'pet-digit-backend.firebasestorage.app');
    expect(options.iosBundleId, 'com.iyunghuang.petdigitchat');
  });
}
