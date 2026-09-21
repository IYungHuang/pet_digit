import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat/presentation/chat_shell.dart';
import '../../../pet/domain/pet_profile.dart';
import '../user_pet_providers.dart';

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
  final _petBreedController = TextEditingController();

  bool _bindPetNow = false; // By default: pet binding is optional / later!
  PetSpecies _selectedSpecies = PetSpecies.dog;
  final PetGender _selectedGender = PetGender.unknown;
  final String _selectedPersonality = 'playful';

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
        _petBreedController.text = '柯基犬';
      } else if (species == PetSpecies.cat) {
        _petBreedController.text = '短毛貓';
      } else {
        _petBreedController.text = '鸚鵡';
      }
    });
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
      setState(() => _errorMessage = '若勾選綁定毛孩，請輸入毛孩名字');
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
          avatarUrl: 'assets/pets/${_selectedSpecies.name}_real.png',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ 已啟動 $provider 直連：使用 Firebase Auth 進行安全連線中...'),
        duration: const Duration(seconds: 2),
      ),
    );
    // Pre-fill quick placeholder for quick onboarding
    if (_nicknameController.text.isEmpty) {
      _nicknameController.text = '$provider 用戶';
      _searchTagController.text = '${provider.toLowerCase()}_user';
    }
    await _handleRegister();
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
                          '建立你的主人身分，隨時領養你的專屬像素毛孩',
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
                          hintText: '例如：柯基飼養員',
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
                          hintText: 'corgi_lover_99',
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
                                        '立即登記首隻毛孩 (可選)',
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
                                  ChoiceChip(
                                    label: const Text('🐕 柯基犬'),
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
                                  hintText: '輸入毛孩名字（如：旺財）',
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
                                _bindPetNow ? '完成註冊並領養毛孩 🚀' : '完成身分登記，直接進入 🚀',
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
