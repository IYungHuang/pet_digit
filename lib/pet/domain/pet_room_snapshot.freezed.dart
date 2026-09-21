// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pet_room_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PetRoomSnapshot {

 String get petId; String get name; PetSpecies get species; String get breed; String get avatarUrl; String get personality;
/// Create a copy of PetRoomSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PetRoomSnapshotCopyWith<PetRoomSnapshot> get copyWith => _$PetRoomSnapshotCopyWithImpl<PetRoomSnapshot>(this as PetRoomSnapshot, _$identity);

  /// Serializes this PetRoomSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PetRoomSnapshot&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.personality, personality) || other.personality == personality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,petId,name,species,breed,avatarUrl,personality);

@override
String toString() {
  return 'PetRoomSnapshot(petId: $petId, name: $name, species: $species, breed: $breed, avatarUrl: $avatarUrl, personality: $personality)';
}


}

/// @nodoc
abstract mixin class $PetRoomSnapshotCopyWith<$Res>  {
  factory $PetRoomSnapshotCopyWith(PetRoomSnapshot value, $Res Function(PetRoomSnapshot) _then) = _$PetRoomSnapshotCopyWithImpl;
@useResult
$Res call({
 String petId, String name, PetSpecies species, String breed, String avatarUrl, String personality
});




}
/// @nodoc
class _$PetRoomSnapshotCopyWithImpl<$Res>
    implements $PetRoomSnapshotCopyWith<$Res> {
  _$PetRoomSnapshotCopyWithImpl(this._self, this._then);

  final PetRoomSnapshot _self;
  final $Res Function(PetRoomSnapshot) _then;

/// Create a copy of PetRoomSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? petId = null,Object? name = null,Object? species = null,Object? breed = null,Object? avatarUrl = null,Object? personality = null,}) {
  return _then(_self.copyWith(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as PetSpecies,breed: null == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,personality: null == personality ? _self.personality : personality // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PetRoomSnapshot].
extension PetRoomSnapshotPatterns on PetRoomSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PetRoomSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PetRoomSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PetRoomSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _PetRoomSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PetRoomSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _PetRoomSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String petId,  String name,  PetSpecies species,  String breed,  String avatarUrl,  String personality)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PetRoomSnapshot() when $default != null:
return $default(_that.petId,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.personality);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String petId,  String name,  PetSpecies species,  String breed,  String avatarUrl,  String personality)  $default,) {final _that = this;
switch (_that) {
case _PetRoomSnapshot():
return $default(_that.petId,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.personality);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String petId,  String name,  PetSpecies species,  String breed,  String avatarUrl,  String personality)?  $default,) {final _that = this;
switch (_that) {
case _PetRoomSnapshot() when $default != null:
return $default(_that.petId,_that.name,_that.species,_that.breed,_that.avatarUrl,_that.personality);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PetRoomSnapshot implements PetRoomSnapshot {
  const _PetRoomSnapshot({required this.petId, required this.name, required this.species, required this.breed, required this.avatarUrl, required this.personality});
  factory _PetRoomSnapshot.fromJson(Map<String, dynamic> json) => _$PetRoomSnapshotFromJson(json);

@override final  String petId;
@override final  String name;
@override final  PetSpecies species;
@override final  String breed;
@override final  String avatarUrl;
@override final  String personality;

/// Create a copy of PetRoomSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PetRoomSnapshotCopyWith<_PetRoomSnapshot> get copyWith => __$PetRoomSnapshotCopyWithImpl<_PetRoomSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PetRoomSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PetRoomSnapshot&&(identical(other.petId, petId) || other.petId == petId)&&(identical(other.name, name) || other.name == name)&&(identical(other.species, species) || other.species == species)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.personality, personality) || other.personality == personality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,petId,name,species,breed,avatarUrl,personality);

@override
String toString() {
  return 'PetRoomSnapshot(petId: $petId, name: $name, species: $species, breed: $breed, avatarUrl: $avatarUrl, personality: $personality)';
}


}

/// @nodoc
abstract mixin class _$PetRoomSnapshotCopyWith<$Res> implements $PetRoomSnapshotCopyWith<$Res> {
  factory _$PetRoomSnapshotCopyWith(_PetRoomSnapshot value, $Res Function(_PetRoomSnapshot) _then) = __$PetRoomSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String petId, String name, PetSpecies species, String breed, String avatarUrl, String personality
});




}
/// @nodoc
class __$PetRoomSnapshotCopyWithImpl<$Res>
    implements _$PetRoomSnapshotCopyWith<$Res> {
  __$PetRoomSnapshotCopyWithImpl(this._self, this._then);

  final _PetRoomSnapshot _self;
  final $Res Function(_PetRoomSnapshot) _then;

/// Create a copy of PetRoomSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? petId = null,Object? name = null,Object? species = null,Object? breed = null,Object? avatarUrl = null,Object? personality = null,}) {
  return _then(_PetRoomSnapshot(
petId: null == petId ? _self.petId : petId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,species: null == species ? _self.species : species // ignore: cast_nullable_to_non_nullable
as PetSpecies,breed: null == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,personality: null == personality ? _self.personality : personality // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
