import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/user_profile.dart';
import '../../../pet/domain/pet_profile.dart';
import '../user_pet_providers.dart';
import 'my_pets_backpack_dialog.dart';
import 'onboarding_wizard_dialog.dart';
import '../screens/auth_screen.dart';

class UserProfileDialog extends ConsumerStatefulWidget {
  const UserProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UserProfileDialog(),
    );
  }

  @override
  ConsumerState<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends ConsumerState<UserProfileDialog> {
  final _nicknameController = TextEditingController();
  final _searchTagController = TextEditingController();
  var _isEditing = false;
  var _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _searchTagController.dispose();
    super.dispose();
  }

  void _startEditing(UserProfile profile) {
    setState(() {
      _isEditing = true;
      _nicknameController.text = profile.nickname;
      _searchTagController.text = profile.searchTag;
      _errorMessage = null;
    });
  }

  Future<void> _saveProfile(UserProfile currentProfile) async {
    final nickname = _nicknameController.text.trim();
    final tag = _searchTagController.text.trim().toLowerCase();

    if (nickname.isEmpty) {
      setState(() => _errorMessage = '請輸入暱稱');
      return;
    }
    if (tag.length < 3 || tag.length > 20) {
      setState(() => _errorMessage = '搜尋標籤長度需為 3~20 字元');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);
      await repo.upsertUserProfile(
        nickname: nickname,
        avatarUrl: currentProfile.avatarUrl,
        searchTag: tag,
      );
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '儲存失敗: $e';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final petsAsync = ref.watch(currentUserPetsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildEmptyState(context);
          }
          return _buildProfileContent(context, profile, petsAsync.valueOrNull ?? []);
        },
        loading: () => const SizedBox(
          height: 250,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(
          height: 200,
          child: Center(child: Text('載入個人資料失敗: $e')),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        const Text(
          '尚未註冊主人身份',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('建立主人與第一隻毛孩的資料即可開始聊天！'),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            OnboardingWizardDialog.show(context);
          },
          icon: const Icon(Icons.pets),
          label: const Text('立即開啟新手引導精靈'),
        ),
      ],
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    UserProfile profile,
    List<PetProfile> pets,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Card
          Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0x1f4361ee),
                child: Icon(Icons.person, size: 38, color: Color(0xff4361ee)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nickname,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff182236),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffeef2ff),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '@${profile.searchTag}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff4361ee),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UID: ${profile.uid}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
                tooltip: _isEditing ? '取消編輯' : '編輯資料',
                onPressed: () {
                  if (_isEditing) {
                    setState(() => _isEditing = false);
                  } else {
                    _startEditing(profile);
                  }
                },
              ),
            ],
          ),

          if (_isEditing) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '主人暱稱',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchTagController,
              decoration: const InputDecoration(
                labelText: '唯一搜尋標籤 (searchTag)',
                helperText: '3~20 個英數字元或底線',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveProfile(profile),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4361ee),
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('儲存修改'),
            ),
          ],

          const Divider(height: 32),

          // Pets Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '我的毛孩 (${pets.length} 隻)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff182236),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  MyPetsBackpackDialog.show(context);
                },
                icon: const Icon(Icons.backpack_outlined, size: 16),
                label: const Text('管理背包'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final pet in pets)
                Chip(
                  avatar: Text(
                    switch (pet.species) {
                      PetSpecies.dog => '🐕',
                      PetSpecies.cat => '🐱',
                      PetSpecies.parrot => '🦜',
                    },
                  ),
                  label: Text(
                    pet.name + (pet.petId == profile.defaultPetId ? ' ⭐主寵' : ''),
                    style: TextStyle(
                      fontWeight: pet.petId == profile.defaultPetId
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  backgroundColor: pet.petId == profile.defaultPetId
                      ? const Color(0xffeef2ff)
                      : Colors.grey.shade100,
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Action Buttons
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(AuthScreen.route());
            },
            icon: const Icon(Icons.login_rounded, color: Color(0xff4361ee)),
            label: const Text('前往獨立註冊與社群登入頁面'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xff4361ee)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              OnboardingWizardDialog.show(context);
            },
            icon: const Icon(Icons.auto_awesome, color: Color(0xff4361ee)),
            label: const Text('重新體驗新手註冊與毛孩綁定'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xff4361ee)),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check),
            label: const Text('返回聊天室'),
          ),
        ],
      ),
    );
  }
}
