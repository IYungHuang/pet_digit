import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet/domain/pet_profile.dart';
import '../user_pet_providers.dart';

class RoomPetSummonDialog extends ConsumerStatefulWidget {
  const RoomPetSummonDialog({
    super.key,
    required this.roomId,
    this.onPetsUpdated,
  });

  final String roomId;
  final VoidCallback? onPetsUpdated;

  static Future<void> show(
    BuildContext context, {
    required String roomId,
    VoidCallback? onPetsUpdated,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => RoomPetSummonDialog(
        roomId: roomId,
        onPetsUpdated: onPetsUpdated,
      ),
    );
  }

  @override
  ConsumerState<RoomPetSummonDialog> createState() =>
      _RoomPetSummonDialogState();
}

class _RoomPetSummonDialogState extends ConsumerState<RoomPetSummonDialog> {
  final Set<String> _selectedPetIds = <String>{};
  bool _initialized = false;
  bool _submitting = false;
  String? _errorMessage;

  void _initSelection(List<PetProfile> allPets, List<String> activePetIds) {
    if (_initialized || allPets.isEmpty) return;
    _initialized = true;

    if (activePetIds.isNotEmpty) {
      _selectedPetIds.addAll(activePetIds);
    } else {
      _selectedPetIds.add(allPets.first.petId);
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

  Future<void> _handleConfirm() async {
    if (_selectedPetIds.isEmpty) {
      setState(() => _errorMessage = '請至少勾選一隻寵物進房陪伴！');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(userPetRepositoryProvider);
      await repo.updateRoomPets(
        roomId: widget.roomId,
        petIds: _selectedPetIds.toList(),
      );

      widget.onPetsUpdated?.call();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🐾 已更新出動寵物！共有 ${_selectedPetIds.length} 隻在房間中跑動'),
            backgroundColor: const Color(0xff4361ee),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(currentUserPetsProvider);
    final membersAsync = ref.watch(roomMembersProvider(widget.roomId));
    final currentUid = ref.watch(currentUserIdProvider);

    final allPets = petsAsync.value ?? [];

    // Find current active pets in this room for caller
    final callerMember = membersAsync.value
        ?.where((m) => m.uid == currentUid)
        .firstOrNull;
    final activeInRoomPetIds =
        callerMember?.pets.map((p) => p.petId).toList() ?? [];

    _initSelection(allPets, activeInRoomPetIds);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(22),
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
                    child: const Text('🐾', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '房間寵物出動調度',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff1f2030),
                          ),
                        ),
                        Text(
                          '勾選在此聊天室同台跑動的寵物 (可部分或全部)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                const SizedBox(height: 12),
              ],

              // Pet List
              if (allPets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('您名下尚無登記寵物，請先至背包登記')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: allPets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final pet = allPets[index];
                    final isChecked = _selectedPetIds.contains(pet.petId);

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            if (_selectedPetIds.length > 1) {
                              _selectedPetIds.remove(pet.petId);
                            } else {
                              _errorMessage = '房間內至少需保留 1 隻寵物陪伴！';
                            }
                          } else {
                            _errorMessage = null;
                            _selectedPetIds.add(pet.petId);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? const Color(0xfff8faff)
                              : const Color(0xfff8f9fa),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isChecked
                                ? const Color(0xff4361ee)
                                : const Color(0xffe9ecef),
                            width: isChecked ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _speciesEmoji(pet.species),
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${pet.breed} • ${pet.personality}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isChecked,
                              activeColor: const Color(0xff4361ee),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _errorMessage = null;
                                    _selectedPetIds.add(pet.petId);
                                  } else {
                                    if (_selectedPetIds.length > 1) {
                                      _selectedPetIds.remove(pet.petId);
                                    } else {
                                      _errorMessage = '房間內至少需保留 1 隻寵物陪伴！';
                                    }
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
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
                    onPressed: _submitting ? null : _handleConfirm,
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('確定出動 (${_selectedPetIds.length} 隻)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
