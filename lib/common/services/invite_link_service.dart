/// Service for managing invite codes, deep link parsing, and shareable URLs.
class InviteLinkData {
  const InviteLinkData({
    required this.code,
    this.roomId,
    this.roomName,
    this.inviterUid,
  });

  final String code;
  final String? roomId;
  final String? roomName;
  final String? inviterUid;
}

class InviteLinkService {
  const InviteLinkService();

  static const String baseWebUrl = 'https://pet-digit-chat.web.app/join';
  static const String customSchemePrefix = 'petdigit://join';

  /// Generates a standardized shareable web invite URL.
  static String buildWebInviteUrl({
    required String roomId,
    String? roomName,
    String? inviterUid,
  }) {
    final code = generateInviteCode(roomId);
    final uri = Uri.parse(baseWebUrl).replace(
      queryParameters: {
        'code': code,
        'room': roomId,
        if (roomName != null && roomName.isNotEmpty) 'name': roomName,
        if (inviterUid != null && inviterUid.isNotEmpty) 'inviter': inviterUid,
      },
    );
    return uri.toString();
  }

  /// Generates a deep link custom URI scheme for direct app invocation.
  static String buildCustomSchemeUrl({
    required String roomId,
    String? roomName,
    String? inviterUid,
  }) {
    final code = generateInviteCode(roomId);
    final uri = Uri.parse(customSchemePrefix).replace(
      queryParameters: {
        'code': code,
        'room': roomId,
        if (roomName != null && roomName.isNotEmpty) 'name': roomName,
        if (inviterUid != null && inviterUid.isNotEmpty) 'inviter': inviterUid,
      },
    );
    return uri.toString();
  }

  /// Derives a clean, human-readable 6-character alphanumeric invite code.
  static String generateInviteCode(String roomId) {
    final clean = roomId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.length >= 6) {
      return clean.substring(clean.length - 6);
    }
    return clean.padRight(6, 'X');
  }

  /// Parses an incoming deep link URL or raw manual invite code string.
  static InviteLinkData? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Check if input is a URI
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('petdigit://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final code = uri.queryParameters['code'] ??
            (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null);
        final room = uri.queryParameters['room'];
        final name = uri.queryParameters['name'];
        final inviter = uri.queryParameters['inviter'];

        if (code != null && code.isNotEmpty) {
          return InviteLinkData(
            code: code.toUpperCase(),
            roomId: room,
            roomName: name,
            inviterUid: inviter,
          );
        }
      }
    }

    // Otherwise treat as plain 4-10 char code
    final cleanCode = trimmed.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (cleanCode.length >= 4 && cleanCode.length <= 16) {
      return InviteLinkData(code: cleanCode);
    }

    return null;
  }
}
