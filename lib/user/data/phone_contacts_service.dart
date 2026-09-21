import '../domain/phone_contact.dart';
import '../../common/services/invite_link_service.dart';
import 'user_pet_repository.dart';

/// Service responsible for simulating/reading phone contacts,
/// matching them with Pet Digit users (like Telegram), and generating SMS invites.
class PhoneContactsService {
  PhoneContactsService({
    List<PhoneContact>? initialContacts,
  }) : _localContacts = initialContacts ?? _defaultLocalPhoneContacts;

  final List<PhoneContact> _localContacts;

  /// Default mock device phonebook for testing and development
  static final List<PhoneContact> _defaultLocalPhoneContacts = [
    const PhoneContact(
      id: 'local_c_1',
      name: '王大明 (波波夥伴)',
      phoneNumber: '0912-345-678',
    ),
    const PhoneContact(
      id: 'local_c_2',
      name: '陳阿福 (柴犬阿福爸)',
      phoneNumber: '0922-333-444',
    ),
    const PhoneContact(
      id: 'local_c_3',
      name: '林美玲 (萌貓咪咪媽)',
      phoneNumber: '0933-555-666',
    ),
    const PhoneContact(
      id: 'local_c_4',
      name: '張小妹 (同事)',
      phoneNumber: '0955-111-222',
    ),
    const PhoneContact(
      id: 'local_c_5',
      name: '李經理',
      phoneNumber: '0966-888-999',
    ),
    const PhoneContact(
      id: 'local_c_6',
      name: '大衛 (大學同學)',
      phoneNumber: '0977-333-222',
    ),
  ];

  /// Simulates requesting permission to read contacts
  Future<bool> requestPermission() async {
    // In Flutter environment or physical device, simulate fast granted check
    await Future.delayed(const Duration(milliseconds: 150));
    return true;
  }

  /// Read device local contacts
  Future<List<PhoneContact>> getLocalContacts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_localContacts);
  }

  /// Match local contacts against Pet Digit user database
  Future<List<PhoneContact>> syncAndMatch({
    required UserPetRepository repository,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final friends = await repository.searchUsers(query: '');
    final friendUids = friends.map((f) => f.uid).toSet();

    final result = <PhoneContact>[];
    for (final contact in _localContacts) {
      final cleanNum = contact.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      // Check matched seeded users by phone number
      if (cleanNum == '0912345678') {
        final isFr = friendUids.contains('user_friend_1');
        result.add(contact.copyWith(
          isRegistered: true,
          registeredUid: 'user_friend_1',
          registeredNickname: '波波小夥伴',
          registeredAvatarUrl: '',
          defaultPetName: '波波 (柴犬)',
          isFriend: isFr,
        ));
      } else if (cleanNum == '0922333444') {
        final isFr = friendUids.contains('user_seed_2');
        result.add(contact.copyWith(
          isRegistered: true,
          registeredUid: 'user_seed_2',
          registeredNickname: '阿福爸爸',
          registeredAvatarUrl: '',
          defaultPetName: '阿福 (柯基)',
          isFriend: isFr,
        ));
      } else if (cleanNum == '0933555666') {
        final isFr = friendUids.contains('user_seed_3');
        result.add(contact.copyWith(
          isRegistered: true,
          registeredUid: 'user_seed_3',
          registeredNickname: '美玲咪咪',
          registeredAvatarUrl: '',
          defaultPetName: '咪咪 (布偶貓)',
          isFriend: isFr,
        ));
      } else {
        // Unregistered contact
        result.add(contact.copyWith(
          isRegistered: false,
          isFriend: false,
        ));
      }
    }

    return result;
  }

  /// Generates a warm SMS / share text with Deeplink and 6-digit invite code
  static String buildSmsInviteText({
    required String contactName,
    required String myInviteCode,
    String? roomId,
  }) {
    final inviteUrl = InviteLinkService.buildWebInviteUrl(
      code: myInviteCode,
      roomId: roomId,
    );

    return '嗨 $contactName！我正在 Pet Digit 玩超可愛的 8-bit 寵物即時聊天，'
        '快來認領你的寵物並跟我一起同台互動吧！'
        '點擊連結立即加入：$inviteUrl '
        '（我的專屬邀請碼：$myInviteCode）';
  }
}
