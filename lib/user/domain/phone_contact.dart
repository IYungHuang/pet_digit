import '../../pet/domain/pet_profile.dart';

/// Represents a phone address-book contact with optional Pet Digit matching status.
class PhoneContact {
  const PhoneContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.isRegistered = false,
    this.registeredUid,
    this.registeredNickname,
    this.registeredAvatarUrl,
    this.defaultPetName,
    this.defaultPetSpecies,
    this.isFriend = false,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final bool isRegistered;
  final String? registeredUid;
  final String? registeredNickname;
  final String? registeredAvatarUrl;
  final String? defaultPetName;
  final PetSpecies? defaultPetSpecies;
  final bool isFriend;

  PhoneContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    bool? isRegistered,
    String? registeredUid,
    String? registeredNickname,
    String? registeredAvatarUrl,
    String? defaultPetName,
    PetSpecies? defaultPetSpecies,
    bool? isFriend,
  }) {
    return PhoneContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isRegistered: isRegistered ?? this.isRegistered,
      registeredUid: registeredUid ?? this.registeredUid,
      registeredNickname: registeredNickname ?? this.registeredNickname,
      registeredAvatarUrl: registeredAvatarUrl ?? this.registeredAvatarUrl,
      defaultPetName: defaultPetName ?? this.defaultPetName,
      defaultPetSpecies: defaultPetSpecies ?? this.defaultPetSpecies,
      isFriend: isFriend ?? this.isFriend,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'isRegistered': isRegistered,
        if (registeredUid != null) 'registeredUid': registeredUid,
        if (registeredNickname != null) 'registeredNickname': registeredNickname,
        if (registeredAvatarUrl != null) 'registeredAvatarUrl': registeredAvatarUrl,
        if (defaultPetName != null) 'defaultPetName': defaultPetName,
        if (defaultPetSpecies != null) 'defaultPetSpecies': defaultPetSpecies?.name,
        'isFriend': isFriend,
      };

  factory PhoneContact.fromJson(Map<String, dynamic> json) {
    PetSpecies? species;
    if (json['defaultPetSpecies'] != null) {
      species = PetSpecies.values.cast<PetSpecies?>().firstWhere(
            (s) => s?.name == json['defaultPetSpecies'],
            orElse: () => null,
          );
    }
    return PhoneContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      isRegistered: json['isRegistered'] as bool? ?? false,
      registeredUid: json['registeredUid'] as String?,
      registeredNickname: json['registeredNickname'] as String?,
      registeredAvatarUrl: json['registeredAvatarUrl'] as String?,
      defaultPetName: json['defaultPetName'] as String?,
      defaultPetSpecies: species,
      isFriend: json['isFriend'] as bool? ?? false,
    );
  }
}
