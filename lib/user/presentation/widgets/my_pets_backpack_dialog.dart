import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet/domain/pet_profile.dart';
import '../user_pet_providers.dart';
import 'pet_edit_dialog.dart';

class MyPetsBackpackDialog extends ConsumerStatefulWidget {
  const MyPetsBackpackDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const MyPetsBackpackDialog(),
    );
  }

  @override
  ConsumerState<MyPetsBackpackDialog> createState() =>
      _MyPetsBackpackDialogState();
}

class _MyPetsBackpackDialogState extends ConsumerState<MyPetsBackpackDialog> {
  bool _showAddForm = false;
  bool _submitting = false;
  String? _errorMessage;

  final _petNameController = TextEditingController();
  final _petBreedController = TextEditingController();
  PetSpecies _selectedSpecies = PetSpecies.dog;
  String _selectedPersonality = 'playful';

  @override
  void dispose() {
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

  String _speciesEmoji(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return '🐕';
      case PetSpecies.cat:
        return '🐱';
      case PetSpecies.parrot:
        return '🦜';
    }
  }

  Future<void> _handleRegisterNewPet() async {
    final name = _petNameController.text.trim();
    final breed = _petBreedController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = '請輸入寵物名字');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);
      await repo.registerPet(
        name: name,
        species: _selectedSpecies,
        breed: breed.isNotEmpty ? breed : '米克斯',
        avatarUrl: 'assets/pets/${_selectedSpecies.name}_real.png',
        personality: _selectedPersonality,
      );

      if (mounted) {
        setState(() {
          _submitting = false;
          _showAddForm = false;
          _petNameController.clear();
          _petBreedController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleSetDefaultPet(String petId) async {
    try {
      final repo = ref.read(userPetRepositoryProvider);
      await repo.setDefaultPet(petId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定主寵失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final petsAsync = ref.watch(currentUserPetsProvider);

    final defaultPetId = profileAsync.value?.defaultPetId ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Dialog Header
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
                      child: const Text('🎒', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '我的寵物背包',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff1f2030),
                            ),
                          ),
                          Text(
                            '管理名下所有寵物夥伴，可自由指定預設出場主寵',
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

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showAddForm) ...[
                        _buildAddPetForm(),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '擁有的寵物夥伴 (${petsAsync.value?.length ?? 0})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_showAddForm)
                            TextButton.icon(
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 18),
                              label: const Text('登記新寵物'),
                              onPressed: () =>
                                  setState(() => _showAddForm = true),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      petsAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Center(
                          child: Text('載入失敗: $err'),
                        ),
                        data: (pets) {
                          if (pets.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  '尚未登記任何寵物夥伴',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pets.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final pet = pets[index];
                              final isDefault = pet.petId == defaultPetId;
                              return _buildPetCard(pet, isDefault);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetCard(PetProfile pet, bool isDefault) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDefault ? const Color(0xfff8faff) : const Color(0xfff8f9fa),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? const Color(0xff4361ee) : const Color(0xffe9ecef),
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xffeff2fe),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _speciesEmoji(pet.species),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff1f2030),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xfffff3bf),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '⭐ 預設主寵',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xffd97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      pet.breed,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '• ${_personalityLabel(pet.personality)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff4361ee),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xff4361ee)),
            tooltip: '編輯寵物資料與頭像',
            onPressed: () => PetEditDialog.show(context, pet: pet),
          ),
          if (!isDefault) ...[
            const SizedBox(width: 4),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                side: const BorderSide(color: Color(0xffcbd5e1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _handleSetDefaultPet(pet.petId),
              child: const Text(
                '設為主寵',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddPetForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff8f9fa),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffdee2e6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '登記新寵物',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _showAddForm = false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              _speciesRadio(PetSpecies.dog, '狗狗', '🐕'),
              const SizedBox(width: 8),
              _speciesRadio(PetSpecies.cat, '貓咪', '🐱'),
              const SizedBox(width: 8),
              _speciesRadio(PetSpecies.parrot, '鸚鵡', '🦜'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _petNameController,
                  decoration: const InputDecoration(
                    hintText: '名字 (如：咪咪)',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _petBreedController,
                  decoration: const InputDecoration(
                    hintText: '品種 (如：金吉拉)',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('性格特徵',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in [
                'playful',
                'curious',
                'calm',
                'energetic',
                'cautious'
              ])
                ChoiceChip(
                  label: Text(_personalityLabel(p),
                      style: const TextStyle(fontSize: 11)),
                  selected: _selectedPersonality == p,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedPersonality = p);
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4361ee),
              foregroundColor: Colors.white,
            ),
            onPressed: _submitting ? null : _handleRegisterNewPet,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('登記寵物'),
          ),
        ],
      ),
    );
  }

  Widget _speciesRadio(PetSpecies species, String label, String emoji) {
    final isSelected = _selectedSpecies == species;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSpecies = species),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xffeff2fe) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xff4361ee)
                  : const Color(0xffdee2e6),
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
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
