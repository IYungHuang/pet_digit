import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/domain/room_member.dart';
import '../../../chat/domain/room_summary.dart';
import '../../../common/services/invite_link_service.dart';
import '../user_pet_providers.dart';

/// Dialog showing active members of the chat room, their designated active pets,
/// enforcing the strict 10-member capacity limit, and providing group-specific invite actions.
class RoomMembersDialog extends ConsumerStatefulWidget {
  const RoomMembersDialog({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.onOpenRoom,
  });

  final String roomId;
  final String roomName;
  final void Function(String roomId) onOpenRoom;

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    required String roomName,
    required void Function(String roomId) onOpenRoom,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => RoomMembersDialog(
        roomId: roomId,
        roomName: roomName,
        onOpenRoom: onOpenRoom,
      ),
    );
  }

  @override
  ConsumerState<RoomMembersDialog> createState() => _RoomMembersDialogState();
}

class _RoomMembersDialogState extends ConsumerState<RoomMembersDialog> {
  String? _successMessage;
  String? _errorMessage;

  void _copyGroupInviteLink() {
    final link = InviteLinkService.buildWebInviteUrl(
      roomId: widget.roomId,
      roomName: widget.roomName,
    );
    Clipboard.setData(ClipboardData(text: link));
    setState(() {
      _successMessage = '群組邀請連結已複製！可透過 LINE / 簡訊分享給好友';
    });
  }

  Future<void> _startDirectChat(String targetUid) async {
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
        setState(() => _errorMessage = '發起私聊失敗：$e');
      }
    }
  }

  Future<void> _showInviteFriendsSheet(List<RoomMember> currentMembers) async {
    final repo = ref.read(userPetRepositoryProvider);
    final existingUids = currentMembers.map((m) => m.uid).toSet();

    final allFriends = await repo.searchUsers(query: '');
    final inviteable = allFriends.where((f) => !existingUids.contains(f.uid)).toList();

    if (!mounted) return;

    if (inviteable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有通訊錄好友都已在此群組中囉！')),
      );
      return;
    }

    final availableSlots = 10 - currentMembers.length;
    final selectedUids = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '邀請好友進群',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '剩餘空位：$availableSlots 人',
                        style: const TextStyle(
                          color: Color(0xff4361ee),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: inviteable.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, idx) {
                        final friend = inviteable[idx];
                        final isSelected = selectedUids.contains(friend.uid);
                        return CheckboxListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: isSelected ? const Color(0xfff0f4ff) : Colors.transparent,
                          title: Text(friend.nickname, style: const TextStyle(fontWeight: FontWeight.w600)),
                          secondary: CircleAvatar(
                            backgroundColor: const Color(0xffeff2fe),
                            child: Text(friend.nickname.isNotEmpty ? friend.nickname[0] : '友'),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setSheetState(() {
                              if (val == true) {
                                if (selectedUids.length >= availableSlots) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('群組上限 10 人，目前最多只能再邀請 $availableSlots 位！')),
                                  );
                                  return;
                                }
                                selectedUids.add(friend.uid);
                              } else {
                                selectedUids.remove(friend.uid);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4361ee),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: selectedUids.isEmpty
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _successMessage = '已發送群組邀請給選取的 ${selectedUids.length} 位好友！';
                              });
                            },
                      child: Text(
                        '確認邀請 (${selectedUids.length} / $availableSlots)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final myUid = ref.watch(currentUserIdProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      child: const Text('👥', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.roomName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff1f2030),
                            ),
                          ),
                          const Text(
                            '群組成員與出戰寵物管理（上限 10 人）',
                            style: TextStyle(fontSize: 11, color: Color(0xff6c757d)),
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

              Expanded(
                child: membersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('載入失敗：$e')),
                  data: (members) {
                    final memberCount = members.length;
                    final isFull = memberCount >= 10;
                    final remainingSlots = 10 - memberCount;

                    return Column(
                      children: [
                        // Capacity Progress Banner
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isFull ? const Color(0xfffef2f2) : const Color(0xfff0fdf4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFull ? const Color(0xfffecaca) : const Color(0xffbbf7d0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '👥 群組成員容納量',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isFull ? const Color(0xff991b1b) : const Color(0xff166534),
                                    ),
                                  ),
                                  Text(
                                    '$memberCount / 10 人 (MVP 上限)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isFull ? const Color(0xffdc2626) : const Color(0xff15803d),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: memberCount / 10,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xffe2e8f0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isFull ? const Color(0xffef4444) : const Color(0xff22c55e),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isFull
                                    ? '⚠️ 目前群組已達到 10 人滿員上限！'
                                    : '✨ 還可以邀請 $remainingSlots 位好友加入共同冒險！',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isFull ? const Color(0xffb91c1c) : const Color(0xff15803d),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Members List
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: members.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final member = members[index];
                              final isMe = member.uid == myUid;
                              final activePet = member.pets.isNotEmpty ? member.pets.first : null;

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
                                          isMe ? '我' : (member.uid.length > 2 ? member.uid.substring(0, 2) : '友'),
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff4361ee)),
                                        ),
                                      ),
                                      if (member.active)
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
                                  title: Row(
                                    children: [
                                      Text(
                                        isMe ? '我 (建立者)' : '成員 ${member.uid}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                      ),
                                      const SizedBox(width: 6),
                                      if (member.role == RoomMemberRole.owner)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xfffef3c7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('👑 群主', style: TextStyle(fontSize: 10, color: Color(0xffb45309))),
                                        ),
                                    ],
                                  ),
                                  subtitle: Wrap(
                                    spacing: 6,
                                    runSpacing: 2,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      if (activePet != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xffeff2fe),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '🐾 出戰：${activePet.name} (${activePet.breed})',
                                            style: const TextStyle(fontSize: 10, color: Color(0xff4361ee)),
                                          ),
                                        )
                                      else
                                        const Text('尚未指定出戰寵物', style: TextStyle(fontSize: 10, color: Color(0xff9ca3af))),
                                      Text(
                                        member.active ? '🟢 在線' : '⚪ 離線',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: member.active ? const Color(0xff16a34a) : const Color(0xff9ca3af),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: isMe
                                      ? null
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xff4361ee),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          onPressed: () => _startDirectChat(member.uid),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.chat_bubble_outline_rounded, size: 14),
                                              SizedBox(width: 4),
                                              Text('私聊', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Bottom Actions: Invite Friends & Copy Invite Link
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xfff1f3f5))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.link_rounded, size: 16),
                                  label: const Text('複製群組連結'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xff4361ee),
                                    side: const BorderSide(color: Color(0xff4361ee)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _copyGroupInviteLink,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.person_add_rounded, size: 16),
                                  label: const Text('邀請好友進群'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFull ? Colors.grey : const Color(0xff4361ee),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: isFull ? null : () => _showInviteFriendsSheet(members),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
