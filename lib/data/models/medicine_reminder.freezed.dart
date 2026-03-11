// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medicine_reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MedicineReminder _$MedicineReminderFromJson(Map<String, dynamic> json) {
  return _MedicineReminder.fromJson(json);
}

/// @nodoc
mixin _$MedicineReminder {
  String get id => throw _privateConstructorUsedError;
  String get medicineName => throw _privateConstructorUsedError;
  String get dose => throw _privateConstructorUsedError; // e.g., 1+0+1
  List<String> get reminderTimes =>
      throw _privateConstructorUsedError; // e.g., ["08:00", "14:00", "20:00"]
  DateTime get startDate => throw _privateConstructorUsedError;
  int get durationDays => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this MedicineReminder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MedicineReminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MedicineReminderCopyWith<MedicineReminder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicineReminderCopyWith<$Res> {
  factory $MedicineReminderCopyWith(
    MedicineReminder value,
    $Res Function(MedicineReminder) then,
  ) = _$MedicineReminderCopyWithImpl<$Res, MedicineReminder>;
  @useResult
  $Res call({
    String id,
    String medicineName,
    String dose,
    List<String> reminderTimes,
    DateTime startDate,
    int durationDays,
    bool isActive,
  });
}

/// @nodoc
class _$MedicineReminderCopyWithImpl<$Res, $Val extends MedicineReminder>
    implements $MedicineReminderCopyWith<$Res> {
  _$MedicineReminderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MedicineReminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? medicineName = null,
    Object? dose = null,
    Object? reminderTimes = null,
    Object? startDate = null,
    Object? durationDays = null,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            medicineName: null == medicineName
                ? _value.medicineName
                : medicineName // ignore: cast_nullable_to_non_nullable
                      as String,
            dose: null == dose
                ? _value.dose
                : dose // ignore: cast_nullable_to_non_nullable
                      as String,
            reminderTimes: null == reminderTimes
                ? _value.reminderTimes
                : reminderTimes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            durationDays: null == durationDays
                ? _value.durationDays
                : durationDays // ignore: cast_nullable_to_non_nullable
                      as int,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MedicineReminderImplCopyWith<$Res>
    implements $MedicineReminderCopyWith<$Res> {
  factory _$$MedicineReminderImplCopyWith(
    _$MedicineReminderImpl value,
    $Res Function(_$MedicineReminderImpl) then,
  ) = __$$MedicineReminderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String medicineName,
    String dose,
    List<String> reminderTimes,
    DateTime startDate,
    int durationDays,
    bool isActive,
  });
}

/// @nodoc
class __$$MedicineReminderImplCopyWithImpl<$Res>
    extends _$MedicineReminderCopyWithImpl<$Res, _$MedicineReminderImpl>
    implements _$$MedicineReminderImplCopyWith<$Res> {
  __$$MedicineReminderImplCopyWithImpl(
    _$MedicineReminderImpl _value,
    $Res Function(_$MedicineReminderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MedicineReminder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? medicineName = null,
    Object? dose = null,
    Object? reminderTimes = null,
    Object? startDate = null,
    Object? durationDays = null,
    Object? isActive = null,
  }) {
    return _then(
      _$MedicineReminderImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        medicineName: null == medicineName
            ? _value.medicineName
            : medicineName // ignore: cast_nullable_to_non_nullable
                  as String,
        dose: null == dose
            ? _value.dose
            : dose // ignore: cast_nullable_to_non_nullable
                  as String,
        reminderTimes: null == reminderTimes
            ? _value._reminderTimes
            : reminderTimes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        durationDays: null == durationDays
            ? _value.durationDays
            : durationDays // ignore: cast_nullable_to_non_nullable
                  as int,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MedicineReminderImpl implements _MedicineReminder {
  const _$MedicineReminderImpl({
    required this.id,
    required this.medicineName,
    required this.dose,
    required final List<String> reminderTimes,
    required this.startDate,
    required this.durationDays,
    this.isActive = true,
  }) : _reminderTimes = reminderTimes;

  factory _$MedicineReminderImpl.fromJson(Map<String, dynamic> json) =>
      _$$MedicineReminderImplFromJson(json);

  @override
  final String id;
  @override
  final String medicineName;
  @override
  final String dose;
  // e.g., 1+0+1
  final List<String> _reminderTimes;
  // e.g., 1+0+1
  @override
  List<String> get reminderTimes {
    if (_reminderTimes is EqualUnmodifiableListView) return _reminderTimes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reminderTimes);
  }

  // e.g., ["08:00", "14:00", "20:00"]
  @override
  final DateTime startDate;
  @override
  final int durationDays;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'MedicineReminder(id: $id, medicineName: $medicineName, dose: $dose, reminderTimes: $reminderTimes, startDate: $startDate, durationDays: $durationDays, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicineReminderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.medicineName, medicineName) ||
                other.medicineName == medicineName) &&
            (identical(other.dose, dose) || other.dose == dose) &&
            const DeepCollectionEquality().equals(
              other._reminderTimes,
              _reminderTimes,
            ) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.durationDays, durationDays) ||
                other.durationDays == durationDays) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    medicineName,
    dose,
    const DeepCollectionEquality().hash(_reminderTimes),
    startDate,
    durationDays,
    isActive,
  );

  /// Create a copy of MedicineReminder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicineReminderImplCopyWith<_$MedicineReminderImpl> get copyWith =>
      __$$MedicineReminderImplCopyWithImpl<_$MedicineReminderImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MedicineReminderImplToJson(this);
  }
}

abstract class _MedicineReminder implements MedicineReminder {
  const factory _MedicineReminder({
    required final String id,
    required final String medicineName,
    required final String dose,
    required final List<String> reminderTimes,
    required final DateTime startDate,
    required final int durationDays,
    final bool isActive,
  }) = _$MedicineReminderImpl;

  factory _MedicineReminder.fromJson(Map<String, dynamic> json) =
      _$MedicineReminderImpl.fromJson;

  @override
  String get id;
  @override
  String get medicineName;
  @override
  String get dose; // e.g., 1+0+1
  @override
  List<String> get reminderTimes; // e.g., ["08:00", "14:00", "20:00"]
  @override
  DateTime get startDate;
  @override
  int get durationDays;
  @override
  bool get isActive;

  /// Create a copy of MedicineReminder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MedicineReminderImplCopyWith<_$MedicineReminderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
