import 'package:flutter_test/flutter_test.dart';
import 'package:chat_pet_mvp/common/services/invite_link_service.dart';

void main() {
  group('InviteLinkService', () {
    test('generateInviteCode derives 6-character code', () {
      final code1 = InviteLinkService.generateInviteCode('room_corgi_123456');
      expect(code1.length, 6);
      expect(code1, '123456');

      final code2 = InviteLinkService.generateInviteCode('dm_abc_xyz');
      expect(code2.length, 6);
      expect(code2, 'ABCXYZ');
    });

    test('buildWebInviteUrl formats query parameters correctly', () {
      final url = InviteLinkService.buildWebInviteUrl(
        roomId: 'room_corgi_party',
        roomName: '柯基聚會',
        inviterUid: 'user_123',
      );

      expect(url, startsWith('https://pet-digit-chat.web.app/join?'));
      expect(url, contains('room=room_corgi_party'));
      expect(url, contains('code='));
      expect(url, contains('inviter=user_123'));
    });

    test('buildCustomSchemeUrl formats petdigit:// scheme', () {
      final url = InviteLinkService.buildCustomSchemeUrl(
        roomId: 'group_9999',
        roomName: '鸚鵡交流群',
      );

      expect(url, startsWith('petdigit://join?'));
      expect(url, contains('room=group_9999'));
    });

    test('parse extracts data from web invite link', () {
      const link = 'https://pet-digit-chat.web.app/join?code=PET888&room=room_cat_club&name=喵星人&inviter=owner_1';
      final data = InviteLinkService.parse(link);

      expect(data, isNotNull);
      expect(data!.code, 'PET888');
      expect(data.roomId, 'room_cat_club');
      expect(data.roomName, '喵星人');
      expect(data.inviterUid, 'owner_1');
    });

    test('parse extracts data from custom scheme link', () {
      const link = 'petdigit://join?code=DOG123&room=room_dog_park';
      final data = InviteLinkService.parse(link);

      expect(data, isNotNull);
      expect(data!.code, 'DOG123');
      expect(data.roomId, 'room_dog_park');
    });

    test('parse handles raw invite code', () {
      final data = InviteLinkService.parse('abc123');
      expect(data, isNotNull);
      expect(data!.code, 'ABC123');
    });

    test('parse returns null for empty or invalid input', () {
      expect(InviteLinkService.parse(''), isNull);
      expect(InviteLinkService.parse('   '), isNull);
      expect(InviteLinkService.parse('a'), isNull);
    });
  });
}
