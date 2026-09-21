import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../pet/domain/pet_profile.dart';
import '../user_pet_providers.dart';

class PetEditDialog extends ConsumerStatefulWidget {
  const PetEditDialog({super.key, required this.pet});

  final PetProfile pet;

  static Future<void> show(BuildContext context, {required PetProfile pet}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PetEditDialog(pet: pet),
    );
  }

  @override
  ConsumerState<PetEditDialog> createState() => _PetEditDialogState();
}

class _PetEditDialogState extends ConsumerState<PetEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late PetGender _selectedGender;
  late String _selectedPersonality;
  late DateTime? _selectedBirthday;
  late String _selectedAvatarUrl;

  bool _submitting = false;
  String? _errorMessage;

  final _personalities = [
    'playful',
    'curious',
    'calm',
    'energetic',
    'cautious',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _breedController = TextEditingController(text: widget.pet.breed);
    _selectedGender = widget.pet.gender;
    _selectedPersonality = widget.pet.personality;
    _selectedBirthday = widget.pet.birthday;
    _selectedAvatarUrl = widget.pet.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
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

  List<String> _getPresetAvatars() {
    switch (widget.pet.species) {
      case PetSpecies.dog:
        return [
          'assets/pets/corgi_real.png',
          'assets/pets/dog_real.png',
          'https://api.dicebear.com/7.x/bottts/png?seed=corgi',
        ];
      case PetSpecies.cat:
        return [
          'assets/pets/cat_real.png',
          'https://api.dicebear.com/7.x/bottts/png?seed=kitty',
        ];
      case PetSpecies.parrot:
        return [
          'assets/pets/parrot_real.png',
          'https://api.dicebear.com/7.x/bottts/png?seed=parrot',
        ];
    }
  }

  Future<void> _pickCustomAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() {
          _selectedAvatarUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選取照片失敗: $e')),
        );
      }
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthday ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _selectedBirthday = picked);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = '請輸入毛孩姓名');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);
      await repo.updatePet(
        petId: widget.pet.petId,
        name: name,
        breed: breed.isNotEmpty ? breed : widget.pet.breed,
        avatarUrl: _selectedAvatarUrl,
        gender: _selectedGender,
        personality: _selectedPersonality,
        birthday: _selectedBirthday,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ 已成功更新毛孩「$name」的資料！'),
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

  @override
  Widget build(BuildContext context) {
    final presets = _getPresetAvatars();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
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
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Color(0xff4361ee),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '編輯毛孩資料 - ${widget.pet.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff212529),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '設定頭像照片、生日、性別與獨特個性',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff6c757d),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xfffee2e2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xffdc2626), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xffdc2626),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 1. Avatar Section
                      const Text(
                        '毛孩頭像',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff495057),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xffeff2fe),
                            child: ClipOval(
                              child: _selectedAvatarUrl.startsWith('http')
                                  ? Image.network(
                                      _selectedAvatarUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Text('🐾',
                                              style: TextStyle(fontSize: 28)),
                                    )
                                  : _selectedAvatarUrl.startsWith('assets/')
                                      ? Image.asset(
                                          _selectedAvatarUrl,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Text('🐾',
                                                  style:
                                                      TextStyle(fontSize: 28)),
                                        )
                                      : const Icon(
                                          Icons.pets,
                                          size: 32,
                                          color: Color(0xff4361ee),
                                        ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    ...presets.map((preset) {
                                      final isSelected =
                                          _selectedAvatarUrl == preset;
                                      return ChoiceChip(
                                        label: Text(
                                          preset.contains('corgi')
                                              ? '柯基'
                                              : preset.contains('cat')
                                                  ? '貓貓'
                                                  : preset.contains('parrot')
                                                      ? '鸚鵡'
                                                      : '像素款',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: const Color(0xffeff2fe),
                                        onSelected: (_) {
                                          setState(() =>
                                              _selectedAvatarUrl = preset);
                                        },
                                      );
                                    }),
                                    ActionChip(
                                      avatar: const Icon(Icons.photo_library,
                                          size: 14),
                                      label: const Text('自訂照片',
                                          style: TextStyle(fontSize: 11)),
                                      onPressed: _pickCustomAvatar,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. Name & Breed
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '毛孩名字',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff495057),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                  '品種',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff495057),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _breedController,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 3. Gender
                      const Text(
                        '毛孩性別',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff495057),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('♂ 男生'),
                            selected: _selectedGender == PetGender.male,
                            selectedColor: const Color(0xffeff2fe),
                            onSelected: (_) => setState(
                                () => _selectedGender = PetGender.male),
                          ),
                          ChoiceChip(
                            label: const Text('♀ 女生'),
                            selected: _selectedGender == PetGender.female,
                            selectedColor: const Color(0xffeff2fe),
                            onSelected: (_) => setState(
                                () => _selectedGender = PetGender.female),
                          ),
                          ChoiceChip(
                            label: const Text('✂ 已結紮'),
                            selected: _selectedGender == PetGender.neutered,
                            selectedColor: const Color(0xffeff2fe),
                            onSelected: (_) => setState(
                                () => _selectedGender = PetGender.neutered),
                          ),
                          ChoiceChip(
                            label: const Text('❓ 未知'),
                            selected: _selectedGender == PetGender.unknown,
                            selectedColor: const Color(0xffeff2fe),
                            onSelected: (_) => setState(
                                () => _selectedGender = PetGender.unknown),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 4. Personality
                      const Text(
                        '個性特質',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff495057),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _personalities.map((p) {
                          final isSelected = _selectedPersonality == p;
                          return ChoiceChip(
                            label: Text(_personalityLabel(p)),
                            selected: isSelected,
                            selectedColor: const Color(0xffeff2fe),
                            onSelected: (_) =>
                                setState(() => _selectedPersonality = p),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 5. Birthday
                      const Text(
                        '生日 / 到家日',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff495057),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickBirthday,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xffdee2e6)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined,
                                  size: 18, color: Color(0xff4361ee)),
                              const SizedBox(width: 10),
                              Text(
                                _selectedBirthday == null
                                    ? '點擊選擇生日日期'
                                    : '${_selectedBirthday!.year} 年 ${_selectedBirthday!.month} 月 ${_selectedBirthday!.day} 日',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedBirthday == null
                                      ? Colors.grey[500]
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedBirthday != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () =>
                                      setState(() => _selectedBirthday = null),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xfff8f9fa),
                  border: Border(top: BorderSide(color: Color(0xfff1f3f5))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _submitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff4361ee),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onPressed: _submitting ? null : _handleSave,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '儲存更新',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
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
