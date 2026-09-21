import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/services/image_optimization_service.dart';
import '../../../pet/domain/pet_profile.dart';
import '../user_pet_providers.dart';
import 'pet_avatar_widget.dart';

class OnboardingWizardDialog extends ConsumerStatefulWidget {
  const OnboardingWizardDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OnboardingWizardDialog(),
    );
  }

  @override
  ConsumerState<OnboardingWizardDialog> createState() =>
      _OnboardingWizardDialogState();
}

class _OnboardingWizardDialogState
    extends ConsumerState<OnboardingWizardDialog> {
  int _step = 0;
  bool _submitting = false;
  String? _errorMessage;

  // Step 1: User Profile
  final _nicknameController = TextEditingController();
  final _searchTagController = TextEditingController();
  String _selectedUserAvatar = 'assets/avatars/user_me.png';

  final _presetUserAvatars = [
    'assets/avatars/user_me.png',
    'assets/avatars/user_friend.png',
    'https://api.dicebear.com/7.x/bottts/png?seed=pet1',
    'https://api.dicebear.com/7.x/bottts/png?seed=pet2',
  ];

  // Step 2: First Pet Profile
  final _petNameController = TextEditingController();
  final _petBreedController = TextEditingController();
  PetSpecies _selectedSpecies = PetSpecies.dog;
  final _selectedGender = PetGender.unknown;
  String _selectedPersonality = 'playful';
  String _selectedPetAvatar = 'assets/pets/corgi_idle_0.png';

  final _personalities = [
    'playful',
    'curious',
    'calm',
    'energetic',
    'cautious',
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    _searchTagController.dispose();
    _petNameController.dispose();
    _petBreedController.dispose();
    super.dispose();
  }

  String _personalityLabel(String key) {
    switch (key) {
      case 'playful':
        return '活潑好動 🎾';
      case 'curious':
        return '好奇寶寶 🔍';
      case 'calm':
        return '溫柔淡定 ☕';
      case 'energetic':
        return '元氣滿滿 ⚡';
      case 'cautious':
        return '謹慎警戒 🛡️';
      default:
        return key;
    }
  }

  void _onSpeciesChanged(PetSpecies species) {
    setState(() {
      _selectedSpecies = species;
      if (species == PetSpecies.dog) {
        _petBreedController.text = '柯基犬';
        _selectedPetAvatar = 'assets/pets/corgi_idle_0.png';
      } else if (species == PetSpecies.cat) {
        _petBreedController.text = '英國短毛貓';
        _selectedPetAvatar = 'assets/pets/cat_idle_0.png';
      } else {
        _petBreedController.text = '玄鳳鸚鵡';
        _selectedPetAvatar = 'assets/pets/parrot_idle_0.png';
      }
    });
  }

  Future<void> _pickPetPhoto() async {
    try {
      final service = ImageOptimizationService();
      final image = await service.showImageSourcePickerAndPick(
        context,
        preset: ImageOptimizationPreset.galleryPhoto,
        title: '為首隻夥伴上傳生活照',
      );
      if (image != null && mounted) {
        setState(() {
          _selectedPetAvatar = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        final message =
            e is ImageOptimizationException ? e.message : '選取照片失敗: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  void _nextStep() {
    setState(() => _errorMessage = null);
    final nickname = _nicknameController.text.trim();
    final tag = _searchTagController.text.trim();

    if (nickname.isEmpty) {
      setState(() => _errorMessage = '請輸入主人暱稱');
      return;
    }
    if (tag.length < 3 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(tag)) {
      setState(() => _errorMessage = '帳號標籤需為 3~20 字元的英文字母、數字或底線');
      return;
    }

    if (_petBreedController.text.isEmpty) {
      _onSpeciesChanged(_selectedSpecies);
    }
    setState(() => _step = 1);
  }

  Future<void> _submitAll() async {
    setState(() {
      _errorMessage = null;
      _submitting = true;
    });

    final petName = _petNameController.text.trim();
    final petBreed = _petBreedController.text.trim();

    if (petName.isEmpty) {
      setState(() {
        _errorMessage = '請替你的第一隻寵物夥伴取個名字';
        _submitting = false;
      });
      return;
    }

    try {
      final repo = ref.read(userPetRepositoryProvider);

      // 1. Upsert User Profile
      await repo.upsertUserProfile(
        nickname: _nicknameController.text.trim(),
        avatarUrl: _selectedUserAvatar,
        searchTag: _searchTagController.text.trim(),
      );

      // 2. Register First Pet
      await repo.registerPet(
        name: petName,
        species: _selectedSpecies,
        breed: petBreed.isNotEmpty ? petBreed : '米克斯',
        avatarUrl: _selectedPetAvatar,
        gender: _selectedGender,
        personality: _selectedPersonality,
        setAsDefault: true,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 歡迎踏入寵物世界！已登記首隻寵物「$petName」'),
            backgroundColor: const Color(0xff4361ee),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submitWithoutPet() async {
    final nickname = _nicknameController.text.trim();
    final tag = _searchTagController.text.trim();

    if (nickname.isEmpty) {
      setState(() => _errorMessage = '請輸入主人暱稱');
      return;
    }
    if (tag.length < 3 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(tag)) {
      setState(() => _errorMessage = '帳號標籤需為 3~20 字元的英文字母、數字或底線');
      return;
    }

    setState(() {
      _errorMessage = null;
      _submitting = true;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);

      // 1. Upsert User Profile without pet
      await repo.upsertUserProfile(
        nickname: nickname,
        avatarUrl: _selectedUserAvatar,
        searchTag: tag,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 歡迎加入！寵物夥伴可隨時於個人資料或背包中領養。'),
            backgroundColor: Color(0xff4361ee),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
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
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xffeff2fe),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _step == 0 ? '👋' : '🐾',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _step == 0 ? '設定主人身份' : '登記第一隻寵物夥伴',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff1f2030),
                            ),
                          ),
                          Text(
                            _step == 0 ? '讓聊天室的朋友與寵物認識你' : '可選步驟：登記你的第一隻寵物夥伴，或稍後再領養',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xff6c757d),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Stepper progress indicator
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xff4361ee),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _step == 1
                              ? const Color(0xff4361ee)
                              : const Color(0xffe9ecef),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xfffee2e2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xfffca5a5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xffb91c1c),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Step content
                if (_step == 0) _buildStep1() else _buildStep2(),

                const SizedBox(height: 24),

                // Footer Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4361ee),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _submitting
                          ? null
                          : (_step == 0 ? _nextStep : _submitAll),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == 0 ? '下一步：登記寵物 ➔' : '完成註冊，踏入世界！ 🎉',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                    if (_step == 1) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() => _step = 0),
                            child: const Text('上一步'),
                          ),
                          TextButton(
                            onPressed: _submitting ? null : _submitWithoutPet,
                            child: const Text(
                              '稍後再綁定 (先去逛逛)',
                              style: TextStyle(
                                color: Color(0xff6c757d),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '主人暱稱',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            hintText: '例如：柯基狂粉、小柴主人',
            filled: true,
            fillColor: const Color(0xfff8f9fa),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdee2e6)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          '專屬帳號標籤 (用於好友搜尋)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _searchTagController,
          decoration: InputDecoration(
            prefixText: '@ ',
            hintText: '例如：corgi_lover_01',
            filled: true,
            fillColor: const Color(0xfff8f9fa),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffdee2e6)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          '選擇主人頭像',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final avatar in _presetUserAvatars)
              GestureDetector(
                onTap: () => setState(() => _selectedUserAvatar = avatar),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedUserAvatar == avatar
                          ? const Color(0xff4361ee)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xffe9ecef),
                    child: Icon(Icons.person, color: Color(0xff6c757d)),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PetAvatarWidget(
              avatarUrl: _selectedPetAvatar,
              species: _selectedSpecies,
              size: 56,
              borderRadius: 14,
              showBorder: true,
              borderColor: const Color(0xff4361ee),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                    label:
                        const Text('上傳生活照', style: TextStyle(fontSize: 12)),
                    onPressed: _pickPetPhoto,
                  ),
                  const Text(
                    '支援手機/電腦相簿照片，建立真實分身',
                    style: TextStyle(fontSize: 11, color: Color(0xff6c757d)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          '寵物物種',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _speciesCard(PetSpecies.dog, '狗狗', '🐕'),
            const SizedBox(width: 10),
            _speciesCard(PetSpecies.cat, '貓咪', '🐱'),
            const SizedBox(width: 10),
            _speciesCard(PetSpecies.parrot, '鸚鵡', '🦜'),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '寵物名字',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _petNameController,
                    decoration: InputDecoration(
                      hintText: '例如：阿福',
                      filled: true,
                      fillColor: const Color(0xfff8f9fa),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffdee2e6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '細分品種',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _petBreedController,
                    decoration: InputDecoration(
                      hintText: '例如：柯基',
                      filled: true,
                      fillColor: const Color(0xfff8f9fa),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffdee2e6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        const Text(
          '性格特徵 (影響聊天室行為風格)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final p in _personalities)
              ChoiceChip(
                label: Text(_personalityLabel(p)),
                selected: _selectedPersonality == p,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedPersonality = p);
                },
                selectedColor: const Color(0xffeff2fe),
                labelStyle: TextStyle(
                  color: _selectedPersonality == p
                      ? const Color(0xff4361ee)
                      : const Color(0xff495057),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _speciesCard(PetSpecies species, String label, String emoji) {
    final isSelected = _selectedSpecies == species;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onSpeciesChanged(species),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xffeff2fe) : const Color(0xfff8f9fa),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xff4361ee)
                  : const Color(0xffdee2e6),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xff4361ee)
                      : const Color(0xff495057),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
