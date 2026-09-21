import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/domain/room_member.dart';
import '../../chat/domain/room_summary.dart';
import '../../chat/presentation/chat_providers.dart';
import '../../pet/domain/pet_profile.dart';
import '../data/fake_user_pet_repository.dart';
import '../data/firebase_user_pet_repository.dart';
import '../data/user_pet_repository.dart';
import '../domain/user_profile.dart';

final fakeUserPetRepositoryProvider = Provider<FakeUserPetRepository>((ref) {
  final repo = FakeUserPetRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final userPetRepositoryProvider = Provider<UserPetRepository>((ref) {
  final useBackend = ref.watch(useBackendTransportProvider);
  if (useBackend) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final functions = ref.watch(firebaseFunctionsProvider);
    if (firestore != null && functions != null) {
      return FirebaseUserPetRepository(
        firestore: firestore,
        functions: functions,
      );
    }
  }
  return ref.watch(fakeUserPetRepositoryProvider);
});

final currentUserIdProvider = Provider<String>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth?.currentUser?.uid ?? 'me';
});

final demoLinkedAccountsProvider =
    StateProvider<List<String>>((ref) => <String>[]);

final linkedProvidersProvider = Provider<List<String>>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth?.currentUser;
  if (user != null && user.providerData.isNotEmpty) {
    return user.providerData.map((p) => p.providerId).toList();
  }
  return ref.watch(demoLinkedAccountsProvider);
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final repo = ref.watch(userPetRepositoryProvider);
  final uid = ref.watch(currentUserIdProvider);
  return repo.watchUserProfile(uid);
});

final currentUserPetsProvider = StreamProvider<List<PetProfile>>((ref) {
  final repo = ref.watch(userPetRepositoryProvider);
  final uid = ref.watch(currentUserIdProvider);
  return repo.watchUserPets(uid);
});

final userRoomSummariesProvider = StreamProvider<List<RoomSummary>>((ref) {
  final repo = ref.watch(userPetRepositoryProvider);
  final uid = ref.watch(currentUserIdProvider);
  return repo.watchRoomSummaries(uid);
});

final roomMembersProvider =
    StreamProvider.family<List<RoomMember>, String>((ref, roomId) {
  final repo = ref.watch(userPetRepositoryProvider);
  return repo.watchRoomMembers(roomId);
});

final isFirstTimeUserProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile == null || profile.defaultPetId.isEmpty,
    orElse: () => false,
  );
});
