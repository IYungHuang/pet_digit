// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PetProfile {

 String get petId; String get ownerUid; String get name; PetSpecies get species; String get breed; String get avatarUrl; List<String> get photoUrls; PetGender get gender; String get personality;@FlexibleNullableDateTimeConverter() DateTime? get birthday;@FlexibleDateTimeConverter() DateTime get createdAt;@FlexibleDateTimeConverter() DateTime get updatedAt;
/// Create a copy of PetProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PetProfileCopyWith<PetProfile> get copyWith => _$PetProfileCopyWithImpl<PetProfile>(this as PetProfile, _$identity);

  /// Serializes this PetProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PetProfile&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.ownerUid, ownerUid) || other.ownerUid == ownerUid)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other.photoUrls, photoUrls)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.personality, personality) || other.personality == personality)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,petId,ownerUid,name,species,breed,avatarUrl,const DeepCollectionEquality().hash(photoUrls),gender,personality,birthday,createdAt,updatedAt);

@override
String toString() {
  return 'PetProfile(petId: $petId, ownerUid: $ownerUid, name: $name, species: $species, breed: $breed, avatarUrl: $avatarUrl, photoUrls: $photoUrls, gender: $gender, personality: $personality, birthday: $birthday, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PetProfileCopyWith<$Res>  {
  factory $PetProfileCopyWith(PetProfile value, $Res Function(PetProfile) _then) = _$PetProfileCopyWithImpl;
@useResult
$Res call({
 String petId, String ownerUid, String name, PetSpecies species, String breed, String avatarUrl, List<String> photoUrls, PetGender gender, String personality,@FlexibleNullableDateTimeConverter() DateTime? birthday,@FlexibleDateTimeConverter() DateTime createdAt,@FlexibleDateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class _$PetProfileCopyWithImpl<$Res>
    implements $PetProfileCopyWith<$Res> {
  _$PetProfileCopyWithImpl(this._self, this._then);

  final PetProfile _self;
  final $Res Function(PetProfile) _then;

/// Create a copy of PetProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? petId = null,Object? ownerUid = null,Object? name = null,Object? species = null,Object? breed = null,Object? avatarUrl = null,Object? photoUrls = null,Object? gender = null,Object? personality = null,Object? birthday = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as PetSpecies,breed: null == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,photoUrls: null == photoUrls ? _self.photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as PetGender,personality: null == personality ? _self.personality : personality // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PetProfile].
extension PetProfilePatterns on PetProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PetProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PetProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PetProfile value)  $default,){
final _that = this;
switch (_that) {
case _PetProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PetProfile value)?  $default,){
final _that = this;
switch (_that) {
case _PetProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String petId,  String ownerUid,  String name,  PetSpecies species,  String breed,  String avatarUrl,  List<String> photoUrls,  PetGender gender,  String personality, @FlexibleNullableDateTimeConverter()  DateTime? birthday, @FlexibleDateTimeConverter()  DateTime createdAt, @FlexibleDateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PetProfile() when $default != null:
return $default(_that.petId,_that.ownerUid,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.photoUrls,_that.gender,_that.personality,_that.birthday,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String petId,  String ownerUid,  String name,  PetSpecies species,  String breed,  String avatarUrl,  List<String> photoUrls,  PetGender gender,  String personality, @FlexibleNullableDateTimeConverter()  DateTime? birthday, @FlexibleDateTimeConverter()  DateTime createdAt, @FlexibleDateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PetProfile():
return $default(_that.petId,_that.ownerUid,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.photoUrls,_that.gender,_that.personality,_that.birthday,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String petId,  String ownerUid,  String name,  PetSpecies species,  String breed,  String avatarUrl,  List<String> photoUrls,  PetGender gender,  String personality, @FlexibleNullableDateTimeConverter()  DateTime? birthday, @FlexibleDateTimeConverter()  DateTime createdAt, @FlexibleDateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PetProfile() when $default != null:
return $default(_that.petId,_that.ownerUid,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.photoUrls,_that.gender,_that.personality,_that.birthday,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PetProfile implements PetProfile {
  const _PetProfile({required this.petId, required this.ownerUid, required this.name, required this.species, required this.breed, required this.avatarUrl, final  List<String> photoUrls = const [], this.gender = PetGender.unknown, this.personality = 'playful', @FlexibleNullableDateTimeConverter() this.birthday, @FlexibleDateTimeConverter() required this.createdAt, @FlexibleDateTimeConverter() required this.updatedAt}): _photoUrls = photoUrls;
  factory _PetProfile.fromJson(Map<String, dynamic> json) => _$PetProfileFromJson(json);

@override final  String petId;
@override final  String ownerUid;
@override final  String name;
@override final  PetSpecies species;
@override final  String breed;
@override final  String avatarUrl;
 final  List<String> _photoUrls;
@override@JsonKey() List<String> get photoUrls {
  if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photoUrls);
}

@override@JsonKey() final  PetGender gender;
@override@JsonKey() final  String personality;
@override@FlexibleNullableDateTimeConverter() final  DateTime? birthday;
@override@FlexibleDateTimeConverter() final  DateTime createdAt;
@override@FlexibleDateTimeConverter() final  DateTime updatedAt;

/// Create a copy of PetProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PetProfileCopyWith<_PetProfile> get copyWith => __$PetProfileCopyWithImpl<_PetProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PetProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PetProfile&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.ownerUid, ownerUid) || other.ownerUid == ownerUid)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other._photoUrls, _photoUrls)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.personality, personality) || other.personality == personality)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,petId,ownerUid,name,species,breed,avatarUrl,const DeepCollectionEquality().hash(_photoUrls),gender,personality,birthday,createdAt,updatedAt);

@override
String toString() {
  return 'PetProfile(petId: $petId, ownerUid: $ownerUid, name: $name, species: $species, breed: $breed, avatarUrl: $avatarUrl, photoUrls: $photoUrls, gender: $gender, personality: $personality, birthday: $birthday, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PetProfileCopyWith<$Res> implements $PetProfileCopyWith<$Res> {
  factory _$PetProfileCopyWith(_PetProfile value, $Res Function(_PetProfile) _then) = __$PetProfileCopyWithImpl;
@override @useResult
$Res call({
 String petId, String ownerUid, String name, PetSpecies species, String breed, String avatarUrl, List<String> photoUrls, PetGender gender, String personality,@FlexibleNullableDateTimeConverter() DateTime? birthday,@FlexibleDateTimeConverter() DateTime createdAt,@FlexibleDateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class __$PetProfileCopyWithImpl<$Res>
    implements _$PetProfileCopyWith<$Res> {
  __$PetProfileCopyWithImpl(this._self, this._then);

  final _PetProfile _self;
  final $Res Function(_PetProfile) _then;

/// Create a copy of PetProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? petId = null,Object? ownerUid = null,Object? name = null,Object? species = null,Object? breed = null,Object? avatarUrl = null,Object? photoUrls = null,Object? gender = null,Object? personality = null,Object? birthday = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_PetProfile(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,ownerUid: null == ownerUid ? _self.ownerUid : ownerUid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as PetSpecies,breed: null == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,photoUrls: null == photoUrls ? _self._photoUrls : photoUrls // ignore: cast_nullable_to_non_nullable
as List<String>,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as PetGender,personality: null == personality ? _self.personality : personality // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
