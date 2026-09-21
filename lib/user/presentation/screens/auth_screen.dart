import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/chat_shell.dart';
import '../../../common/services/image_optimization_service.dart';
import '../../../pet/domain/pet_profile.dart';
import '../user_pet_providers.dart';
import '../widgets/pet_avatar_widget.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  static MaterialPageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AuthScreen());
  }

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _nicknameController = TextEditingController();
  final _searchTagController = TextEditingController();
  final _petNameController = TextEditingController();
  final _petBreedController = TextEditingController(text: '柴犬');

  bool _bindPetNow = false; // By default: pet binding is optional / later!
  PetSpecies _selectedSpecies = PetSpecies.dog;
  final PetGender _selectedGender = PetGender.unknown;
  final String _selectedPersonality = 'playful';
  String _petAvatarUrl = 'assets/pets/corgi_idle_0.png';

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    _searchTagController.dispose();
    _petNameController.dispose();
    _petBreedController.dispose();
    super.dispose();
  }

  void _onSpeciesChanged(PetSpecies species) {
    setState(() {
      _selectedSpecies = species;
      if (species == PetSpecies.dog) {
        _petBreedController.text = '柴犬';
        _petAvatarUrl = 'assets/pets/corgi_idle_0.png';
      } else if (species == PetSpecies.cat) {
        _petBreedController.text = '英國短毛貓';
        _petAvatarUrl = 'assets/pets/cat_idle_0.png';
      } else {
        _petBreedController.text = '玄鳳鸚鵡';
        _petAvatarUrl = 'assets/pets/parrot_idle_0.png';
      }
    });
  }

  Future<void> _pickCustomAvatar() async {
    try {
      final service = ImageOptimizationService();
      final image = await service.showImageSourcePickerAndPick(
        context,
        preset: ImageOptimizationPreset.avatar,
        title: '設定寵物代表頭像',
      );
      if (image != null && mounted) {
        setState(() {
          _petAvatarUrl = image.path;
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

  Future<void> _handleRegister() async {
    final nickname = _nicknameController.text.trim();
    final searchTag = _searchTagController.text.trim();

    if (nickname.isEmpty) {
      setState(() => _errorMessage = '請輸入使用者暱稱');
      return;
    }
    if (searchTag.length < 3 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(searchTag)) {
      setState(() => _errorMessage = '帳號搜尋標籤需為 3~20 字元英數底線');
      return;
    }

    if (_bindPetNow && _petNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = '若勾選登記寵物，請輸入寵物名字');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);

      // 1. Create or update profile
      await repo.upsertUserProfile(
        nickname: nickname,
        avatarUrl: 'assets/avatars/user_me.png',
        searchTag: searchTag,
      );

      // 2. If user chose to bind pet now, register pet
      if (_bindPetNow) {
        final petName = _petNameController.text.trim();
        final petBreed = _petBreedController.text.trim();
        await repo.registerPet(
          name: petName,
          species: _selectedSpecies,
          breed: petBreed.isNotEmpty ? petBreed : '米克斯',
          avatarUrl: _petAvatarUrl,
          gender: _selectedGender,
          personality: _selectedPersonality,
          setAsDefault: true,
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const ChatShell(
              showDemoAttachments: true,
              autoShowOnboarding: false,
            ),
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

  Future<void> _handleThirdPartyLogin(String provider) async {
    final providerId =
        provider.toLowerCase() == 'google' ? 'google.com' : 'apple.com';

    // Mark provider as linked
    ref.read(demoLinkedAccountsProvider.notifier).update((state) {
      return state.contains(providerId) ? state : [...state, providerId];
    });

    final defaultNick = '$provider 使用者';
    final defaultTag = '${provider.toLowerCase()}_user';

    if (_nicknameController.text.isEmpty) {
      _nicknameController.text = defaultNick;
      _searchTagController.text = defaultTag;
    }

    // Show prompt to pick pet or proceed
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _ThirdPartyConnectedPetDialog(
        provider: provider,
        onProceed: (petName, species, breed, avatarUrl, gender, personality) async {
          Navigator.of(dialogCtx).pop();

          setState(() {
            _submitting = true;
            _errorMessage = null;
          });

          try {
            final repo = ref.read(userPetRepositoryProvider);
            await repo.upsertUserProfile(
              nickname: _nicknameController.text.trim().isNotEmpty
                  ? _nicknameController.text.trim()
                  : defaultNick,
              avatarUrl: 'assets/avatars/user_me.png',
              searchTag: _searchTagController.text.trim().isNotEmpty
                  ? _searchTagController.text.trim()
                  : defaultTag,
            );

            if (petName != null && petName.isNotEmpty) {
              final chosenSpecies = species ?? PetSpecies.dog;
              final fallbackAvatar = switch (chosenSpecies) {
                PetSpecies.dog => 'assets/pets/corgi_idle_0.png',
                PetSpecies.cat => 'assets/pets/cat_idle_0.png',
                PetSpecies.parrot => 'assets/pets/parrot_idle_0.png',
              };
              await repo.registerPet(
                name: petName,
                species: chosenSpecies,
                breed: (breed != null && breed.isNotEmpty) ? breed : '米克斯',
                avatarUrl: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? avatarUrl
                    : fallbackAvatar,
                gender: gender ?? PetGender.unknown,
                personality: personality ?? 'playful',
                setAsDefault: true,
              );
            }

            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const ChatShell(
                    showDemoAttachments: true,
                    autoShowOnboarding: false,
                  ),
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fe),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xffe9ecef)),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Logo & Title
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xffeff2fe),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('🐾', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Pixel Pals 冒險入口',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff1f2030),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          '建立你的主人身分，隨時領養你的專屬數位寵物夥伴',
                          style: TextStyle(fontSize: 13, color: Color(0xff6c757d)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Third-Party Fast Auth Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Text('🌐', style: TextStyle(fontSize: 16)),
                              label: const Text('Google 帳號',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xffdee2e6)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _submitting
                                  ? null
                                  : () => _handleThirdPartyLogin('Google'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.apple, size: 18),
                              label: const Text('Apple 帳號',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _submitting
                                  ? null
                                  : () => _handleThirdPartyLogin('Apple'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Divider with "或使用自訂暱稱註冊"
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xffe9ecef))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '或自訂身分登記',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xffe9ecef))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xfffee2e2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xffdc2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form Fields
                      const Text(
                        '主人暱稱',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          hintText: '例如：寵物飼養員',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          filled: true,
                          fillColor: const Color(0xfff8f9fa),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xffdee2e6)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        '專屬搜尋標籤 (@tag)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _searchTagController,
                        decoration: InputDecoration(
                          hintText: 'pixel_master_88',
                          prefixIcon: const Icon(Icons.alternate_email, size: 20),
                          filled: true,
                          fillColor: const Color(0xfff8f9fa),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xffdee2e6)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Optional Pet Binding Checkbox Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xfff8f9fe),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _bindPetNow
                                ? const Color(0xff4361ee)
                                : const Color(0xffe2e8f0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _bindPetNow,
                                  activeColor: const Color(0xff4361ee),
                                  onChanged: (val) {
                                    setState(() {
                                      _bindPetNow = val ?? false;
                                      if (_bindPetNow &&
                                          _petBreedController.text.isEmpty) {
                                        _onSpeciesChanged(_selectedSpecies);
                                      }
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '立即登記首隻寵物夥伴 (可選)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '未勾選將於進入 App 後隨時在背包中領養',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xff6c757d),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_bindPetNow) ...[
                              const Divider(height: 20),
                              Row(
                                children: [
                                  PetAvatarWidget(
                                    avatarUrl: _petAvatarUrl,
                                    species: _selectedSpecies,
                                    size: 56,
                                    borderRadius: 14,
                                    showBorder: true,
                                    borderColor: const Color(0xff4361ee),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                              Icons.add_a_photo_outlined,
                                              size: 16),
                                          label: const Text('上傳生活照',
                                              style: TextStyle(fontSize: 12)),
                                          onPressed: _pickCustomAvatar,
                                        ),
                                        const Text(
                                          '上傳家中寵物真實生活照',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xff6c757d)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('🐕 狗狗'),
                                    selected: _selectedSpecies == PetSpecies.dog,
                                    onSelected: (_) =>
                                        _onSpeciesChanged(PetSpecies.dog),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('🐱 貓咪'),
                                    selected: _selectedSpecies == PetSpecies.cat,
                                    onSelected: (_) =>
                                        _onSpeciesChanged(PetSpecies.cat),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('🦜 鸚鵡'),
                                    selected: _selectedSpecies == PetSpecies.parrot,
                                    onSelected: (_) =>
                                        _onSpeciesChanged(PetSpecies.parrot),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _petNameController,
                                decoration: InputDecoration(
                                  hintText: '輸入寵物名字（如：旺財、波波）',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _petBreedController,
                                decoration: InputDecoration(
                                  hintText: '真實品種（如：柴犬、柯基、英短）',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4361ee),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _submitting ? null : _handleRegister,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _bindPetNow ? '完成註冊並登記寵物 🚀' : '完成身分登記，直接進入 🚀',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),

                      // Guest quick pass
                      Center(
                        child: TextButton(
                          onPressed: _submitting
                              ? null
                              : () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const ChatShell(
                                        showDemoAttachments: true,
                                        autoShowOnboarding: false,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text(
                            '以訪客身分直接參觀聊天室 ➔',
                            style: TextStyle(
                              color: Color(0xff6c757d),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThirdPartyConnectedPetDialog extends StatefulWidget {
  const _ThirdPartyConnectedPetDialog({
    required this.provider,
    required this.onProceed,
  });

  final String provider;
  final void Function(
    String? petName,
    PetSpecies? species,
    String? breed,
    String? avatarUrl,
    PetGender? gender,
    String? personality,
  ) onProceed;

  @override
  State<_ThirdPartyConnectedPetDialog> createState() =>
      _ThirdPartyConnectedPetDialogState();
}

class _ThirdPartyConnectedPetDialogState
    extends State<_ThirdPartyConnectedPetDialog> {
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController(text: '柴犬');
  PetSpecies _selectedSpecies = PetSpecies.dog;
  String _avatarUrl = 'assets/pets/corgi_idle_0.png';
  PetGender _selectedGender = PetGender.unknown;
  final String _selectedPersonality = 'playful';

  final Map<PetSpecies, List<String>> _breedSuggestions = const {
    PetSpecies.dog: ['柴犬', '柯基犬', '貴賓犬', '黃金獵犬', '米克斯'],
    PetSpecies.cat: ['英國短毛貓', '美國短毛貓', '橘貓', '布偶貓', '米克斯'],
    PetSpecies.parrot: ['玄鳳鸚鵡', '虎皮鸚鵡', '金太陽', '小櫻鸚鵡', '灰鸚鵡'],
  };

  final Map<PetSpecies, List<String>> _presetAvatars = const {
    PetSpecies.dog: [
      'assets/pets/corgi_idle_0.png',
      'https://images.unsplash.com/photo-1589965716319-4a041b58fa8a?fit=crop&crop=faces&w=400&h=400&q=80',
      'https://images.unsplash.com/photo-1575535468632-345892291673?fit=crop&crop=top&w=400&h=400&q=80',
    ],
    PetSpecies.cat: [
      'assets/pets/cat_idle_0.png',
      'https://images.unsplash.com/photo-1585373683920-671438c82bfa?fit=crop&crop=top&w=400&h=400&q=80',
      'https://images.unsplash.com/photo-1629624467541-f73ef8f12df2?fit=crop&crop=top&w=400&h=400&q=80',
    ],
    PetSpecies.parrot: [
      'assets/pets/parrot_idle_0.png',
      'https://images.unsplash.com/photo-1552728089-57bdde30beb3?fit=crop&crop=faces&w=400&h=400&q=80',
      'https://images.unsplash.com/photo-1517101724602-c257fe568157?fit=crop&crop=faces&w=400&h=400&q=80',
    ],
  };

  @override
  void dispose() {
    _petNameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  void _onSpecies(PetSpecies s) {
    setState(() {
      _selectedSpecies = s;
      _breedController.text = _breedSuggestions[s]!.first;
      _avatarUrl = _presetAvatars[s]!.first;
    });
  }

  Future<void> _pickPetPhoto() async {
    try {
      final service = ImageOptimizationService();
      final image = await service.showImageSourcePickerAndPick(
        context,
        preset: ImageOptimizationPreset.galleryPhoto,
        title: '上傳現實寵物生活照',
      );
      if (image != null && mounted) {
        setState(() {
          _avatarUrl = image.path;
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

  String _presetLabel(String url) {
    if (url.startsWith('assets/')) return '像素款';
    if (url.contains('58996')) return '柯基寫真';
    if (url.contains('57553')) return '柴犬寫真';
    if (url.contains('58537')) return '布偶寫真';
    if (url.contains('62962')) return '英短寫真';
    if (url.contains('55272')) return '鸚鵡寫真';
    if (url.contains('51710') || url.contains('54494')) return '玄鳳寫真';
    return '範本寫真';
  }

  @override
  Widget build(BuildContext context) {
    final presets = _presetAvatars[_selectedSpecies] ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Connection Success Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xffeffcf6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffa7f3d0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xff059669), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.provider} 帳號已成功連結 ✔',
                              style: const TextStyle(
                                color: Color(0xff065f46),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '已透過 Firebase Auth 安全憑證完成授權 (${widget.provider.toLowerCase()}.com)',
                              style: const TextStyle(
                                color: Color(0xff047857),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Question / Slogan
                const Text(
                  '🎉 歡迎踏入數位寵物世界！',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  '將您現實中的心愛寵物綁進數位世界，建立專屬分身（可稍後於背包綁定）',
                  style: TextStyle(fontSize: 12, color: Color(0xff6c757d)),
                ),
                const SizedBox(height: 16),

                // 3. Media / Real Photo Upload Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xfff8faff),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PetAvatarWidget(
                            avatarUrl: _avatarUrl,
                            species: _selectedSpecies,
                            size: 68,
                            borderRadius: 16,
                            showBorder: true,
                            borderColor: const Color(0xff4361ee),
                            borderWidth: 2,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📸 上傳現實寵物生活照',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff1f2030),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  '支援手機/電腦相簿照片，打造專屬代表分身',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xff6c757d),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_a_photo_outlined,
                                      size: 15),
                                  label: const Text('選取生活照',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff4361ee),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _pickPetPhoto,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text(
                            '或挑選範本寫真：',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xff6c757d)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: presets.map((preset) {
                                  final isSel = _avatarUrl == preset;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(_presetLabel(preset),
                                          style: const TextStyle(fontSize: 10)),
                                      selected: isSel,
                                      onSelected: (_) => setState(() {
                                        _avatarUrl = preset;
                                        if (preset.contains('58996')) {
                                          _breedController.text = '柯基犬';
                                        } else if (preset.contains('57553')) {
                                          _breedController.text = '柴犬';
                                        } else if (preset.contains('58537')) {
                                          _breedController.text = '布偶貓';
                                        } else if (preset.contains('62962')) {
                                          _breedController.text = '英國短毛貓';
                                        }
                                      }),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Species selector
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('🐕 狗狗'),
                      selected: _selectedSpecies == PetSpecies.dog,
                      onSelected: (_) => _onSpecies(PetSpecies.dog),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🐱 貓咪'),
                      selected: _selectedSpecies == PetSpecies.cat,
                      onSelected: (_) => _onSpecies(PetSpecies.cat),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🦜 鸚鵡'),
                      selected: _selectedSpecies == PetSpecies.parrot,
                      onSelected: (_) => _onSpecies(PetSpecies.parrot),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5. Name Input
                TextField(
                  controller: _petNameController,
                  decoration: InputDecoration(
                    labelText: '寵物名字',
                    hintText: '替牠取個名字（如：旺財、波波）',
                    filled: true,
                    fillColor: const Color(0xfff8f9fa),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffdee2e6)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 6. Breed Input & Suggestions
                TextField(
                  controller: _breedController,
                  decoration: InputDecoration(
                    labelText: '品種（如：柴犬、柯基、英短）',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xfff8f9fa),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xffdee2e6)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('熱門品種：',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xff6c757d))),
                      ...(_breedSuggestions[_selectedSpecies] ?? []).map((b) =>
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(b,
                                  style: const TextStyle(fontSize: 11)),
                              onPressed: () =>
                                  setState(() => _breedController.text = b),
                              visualDensity: VisualDensity.compact,
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 7. Gender
                Row(
                  children: [
                    const Text('性別：',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('♂ 公', style: TextStyle(fontSize: 11)),
                      selected: _selectedGender == PetGender.male,
                      onSelected: (_) =>
                          setState(() => _selectedGender = PetGender.male),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('♀ 母', style: TextStyle(fontSize: 11)),
                      selected: _selectedGender == PetGender.female,
                      onSelected: (_) =>
                          setState(() => _selectedGender = PetGender.female),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label:
                          const Text('✂️ 結紮', style: TextStyle(fontSize: 11)),
                      selected: _selectedGender == PetGender.neutered,
                      onSelected: (_) =>
                          setState(() => _selectedGender = PetGender.neutered),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Actions
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4361ee),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final name = _petNameController.text.trim();
                    final breed = _breedController.text.trim();
                    widget.onProceed(
                      name.isNotEmpty ? name : '阿福',
                      _selectedSpecies,
                      breed.isNotEmpty ? breed : '米克斯',
                      _avatarUrl,
                      _selectedGender,
                      _selectedPersonality,
                    );
                  },
                  child: const Text(
                    '🐾 馬上領養寵物夥伴並進入',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => widget.onProceed(
                      null, null, null, null, null, null),
                  child: const Text(
                    '稍後再領養，直接進入聊天室 ➔',
                    style: TextStyle(color: Color(0xff6c757d)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
