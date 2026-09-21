import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/domain/room_summary.dart';
import '../../data/user_pet_repository.dart';
import '../user_pet_providers.dart';

class CreateRoomDialog extends ConsumerStatefulWidget {
  const CreateRoomDialog({
    super.key,
    required this.onRoomCreated,
  });

  final void Function(String roomId) onRoomCreated;

  static Future<void> show(
    BuildContext context, {
    required void Function(String roomId) onRoomCreated,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => CreateRoomDialog(onRoomCreated: onRoomCreated),
    );
  }

  @override
  ConsumerState<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<CreateRoomDialog> {
  RoomType _roomType = RoomType.direct;
  final _searchController = TextEditingController();
  final _groupNameController = TextEditingController();

  List<UserSearchResult> _searchResults = [];
  final Set<String> _selectedUids = {};
  bool _searching = false;
  bool _creating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searching = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);
      final results = await repo.searchUsers(query: query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleCreate() async {
    if (_selectedUids.isEmpty) {
      setState(() => _errorMessage = '請選擇至少一位好友！');
      return;
    }

    if (_roomType == RoomType.group &&
        _groupNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = '請為群組命名！');
      return;
    }

    if (_roomType == RoomType.group && _selectedUids.length > 9) {
      setState(() => _errorMessage = '群組上限為 10 人（最多邀請 9 位好友）！');
      return;
    }

    setState(() {
      _creating = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);
      final result = await repo.createRoom(
        type: _roomType,
        inviteeUids: _selectedUids.toList(),
        name: _roomType == RoomType.group
            ? _groupNameController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onRoomCreated(result.roomId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _creating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      child: const Text('💬', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '發起新對話',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff1f2030),
                            ),
                          ),
                          Text(
                            '搜尋好友並發起 1 對 1 私聊或建立多人群聊',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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

              // Mode Tabs
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('👤 1 對 1 私聊')),
                        selected: _roomType == RoomType.direct,
                        selectedColor: const Color(0xffeff2fe),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _roomType = RoomType.direct;
                              if (_selectedUids.length > 1) {
                                _selectedUids.clear();
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('👥 多人群聊')),
                        selected: _roomType == RoomType.group,
                        selectedColor: const Color(0xffeff2fe),
                        onSelected: (val) {
                          if (val) setState(() => _roomType = RoomType.group);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (_roomType == RoomType.group)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      hintText: '輸入群組名稱 (例如：柯基同樂會)',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

              // Search Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜尋好友暱稱或 @searchTag...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) => _performSearch(val),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              // User Results List
              Expanded(
                child: _searching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              '未找到相關好友',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (_, index) {
                              final user = _searchResults[index];
                              final isSelected =
                                  _selectedUids.contains(user.uid);

                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                tileColor: isSelected
                                    ? const Color(0xfff8faff)
                                    : const Color(0xfff8f9fa),
                                leading: const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Color(0xffeff2fe),
                                  child: Icon(Icons.person,
                                      color: Color(0xff4361ee)),
                                ),
                                title: Text(
                                  user.nickname,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text('UID: ${user.uid}'),
                                trailing: _roomType == RoomType.direct
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xff4361ee),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                        ),
                                        onPressed: _creating
                                            ? null
                                            : () {
                                                _selectedUids.clear();
                                                _selectedUids.add(user.uid);
                                                _handleCreate();
                                              },
                                        child: const Text('發起對話'),
                                      )
                                    : Checkbox(
                                        value: isSelected,
                                        activeColor: const Color(0xff4361ee),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              if (_selectedUids.length >= 9) {
                                                _errorMessage = '群組上限為 10 人（含您最多邀請 9 位好友）';
                                                return;
                                              }
                                              _selectedUids.add(user.uid);
                                            } else {
                                              _selectedUids.remove(user.uid);
                                            }
                                          });
                                        },
                                      ),
                                onTap: _roomType == RoomType.group
                                    ? () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedUids.remove(user.uid);
                                          } else {
                                            if (_selectedUids.length >= 9) {
                                              _errorMessage = '群組上限為 10 人（含您最多邀請 9 位好友）';
                                              return;
                                            }
                                            _selectedUids.add(user.uid);
                                          }
                                        });
                                      }
                                    : null,
                              );
                            },
                          ),
              ),

              // Footer for group creation
              if (_roomType == RoomType.group)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xfff1f3f5))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('已選取 ${_selectedUids.length} / 9 位好友 (上限10人)'),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4361ee),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _creating ? null : _handleCreate,
                        child: _creating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('建立群聊'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
