import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/domain/room_summary.dart';
import '../../../common/services/invite_link_service.dart';
import '../../data/user_pet_repository.dart';
import '../user_pet_providers.dart';

class ContactsDialog extends ConsumerStatefulWidget {
  const ContactsDialog({
    super.key,
    required this.onOpenRoom,
  });

  final void Function(String roomId) onOpenRoom;

  static Future<void> show(
    BuildContext context, {
    required void Function(String roomId) onOpenRoom,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ContactsDialog(onOpenRoom: onOpenRoom),
    );
  }

  @override
  ConsumerState<ContactsDialog> createState() => _ContactsDialogState();
}

class _ContactsDialogState extends ConsumerState<ContactsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  List<UserSearchResult> _friends = [];
  List<UserSearchResult> _searchResults = [];
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialFriends() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(userPetRepositoryProvider);
      final results = await repo.searchUsers(query: '');
      if (mounted) {
        setState(() {
          _friends = results;
          _searchResults = results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);
      final results = await repo.searchUsers(query: query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = '搜尋失敗：$e';
        });
      }
    }
  }

  Future<void> _startDirectChat(String targetUid) async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(userPetRepositoryProvider);
      final result = await repo.createRoom(
        type: RoomType.direct,
        inviteeUids: [targetUid],
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onOpenRoom(result.roomId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = '發起對話失敗：$e';
        });
      }
    }
  }

  void _handleJoinByCode() {
    final text = _inviteCodeController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = '請輸入邀請碼或邀請連結！');
      return;
    }

    final parsed = InviteLinkService.parse(text);
    if (parsed == null) {
      setState(() => _errorMessage = '無法識別的邀請碼或連結格式');
      return;
    }

    // If roomId is embedded or code was parsed
    final targetRoomId = parsed.roomId ?? 'group_${parsed.code.toLowerCase()}';
    Navigator.of(context).pop();
    widget.onOpenRoom(targetRoomId);
  }

  void _copyMyInviteLink() {
    final link = InviteLinkService.buildWebInviteUrl(
      roomId: 'public_lobby',
      roomName: 'PetDigit 公共大廳',
    );
    Clipboard.setData(ClipboardData(text: link));
    setState(() {
      _successMessage = '專屬邀請連結已複製到剪貼簿！可透過 LINE / 簡訊分享給好友';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xfff1f3f5))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xffeff2fe),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('📖', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '通訊錄與好友',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff1f2030),
                            ),
                          ),
                          Text(
                            '管理好友、發起 1 對 1 私聊或透過邀請碼進群',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xff6c757d),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // TabBar
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xff4361ee),
                unselectedLabelColor: const Color(0xff6c757d),
                indicatorColor: const Color(0xff4361ee),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: '👥 好友名單'),
                  Tab(text: '🔍 搜尋加好友'),
                  Tab(text: '🎟️ 邀請碼 / 連結'),
                ],
              ),

              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  color: const Color(0xfffee2e2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xffdc2626), fontSize: 12),
                  ),
                ),

              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  color: const Color(0xffecfdf5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Color(0xff059669), fontSize: 12),
                  ),
                ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Friends
                    _buildFriendsTab(),

                    // Tab 2: Search
                    _buildSearchTab(),

                    // Tab 3: Invite Code & Deeplink
                    _buildInviteCodeTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_loading && _friends.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xffadb5bd)),
            const SizedBox(height: 8),
            const Text('通訊錄尚無好友', style: TextStyle(color: Color(0xff6c757d))),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('搜尋新好友'),
              onPressed: () => _tabController.animateTo(1),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _friends.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final friend = _friends[index];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xfff8f9fa),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffe9ecef)),
          ),
          child: ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xffeff2fe),
                  child: Text(
                    friend.nickname.isNotEmpty ? friend.nickname[0] : '友',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xff4361ee),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xff16a34a),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              friend.nickname,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xffeff2fe),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '🐾 代表寵物出戰中',
                    style: TextStyle(fontSize: 10, color: Color(0xff4361ee)),
                  ),
                ),
                const SizedBox(width: 6),
                const Text('🟢 在線', style: TextStyle(fontSize: 11, color: Color(0xff16a34a))),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4361ee),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _startDirectChat(friend.uid),
              child: const Text('💬 私聊', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜尋好友暱稱、@searchTag 或手機號碼...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          '未找到符合的用戶',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            tileColor: const Color(0xfff8f9fa),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xffeff2fe),
                              child: Icon(Icons.person, color: Color(0xff4361ee)),
                            ),
                            title: Text(user.nickname, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('UID: ${user.uid}'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff4361ee),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _startDirectChat(user.uid),
                              child: const Text('發起對話'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Enter code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xfff8faff),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🎟️', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      '輸入群組邀請碼或 Deeplink',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '貼上好友分享的專屬邀請碼（6碼英數）或完整連結，即可立即加入該群聊！',
                  style: TextStyle(fontSize: 11, color: Color(0xff6c757d)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inviteCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: '例：PET9AB 或 petdigit://...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4361ee),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _handleJoinByCode,
                      child: const Text('加入群組'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Share link
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xfffaf5ff),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xfff3e8ff)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🔗', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      '分享我的專屬邀請連結',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '透過 LINE、簡訊或社交軟體發送連結給未安裝的好友，對方點擊即可下載並自動將雙方綁定為好友！',
                  style: TextStyle(fontSize: 11, color: Color(0xff6c757d)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('複製我的專屬邀請連結'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff7c3aed),
                    side: const BorderSide(color: Color(0xffc084fc)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _copyMyInviteLink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
