//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// on_time — срок не скоро; due_soon — меньше суток; overdue — просрочен; answered — первый ответ уже дан; no_deadline — срока нет (отзыв или нет ответственного) 
enum DueState {
  onTime._(r'on_time'),
  dueSoon._(r'due_soon'),
  overdue._(r'overdue'),
  answered._(r'answered'),
  noDeadline._(r'no_deadline'),
  ;

  /// Instantiate a new enum with the provided value.
  const DueState._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DueState] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DueState? fromJson(dynamic value) => DueStateTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DueState]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DueState> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DueState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DueState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DueState] to String,
/// and [decode] dynamic data back to [DueState].
class DueStateTypeTransformer {
  factory DueStateTypeTransformer() => _instance ??= const DueStateTypeTransformer._();

  const DueStateTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(DueState data) => data._value;

  /// Returns the instance of [DueState] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DueState? decode(dynamic data, {bool allowNull = true}) {
    if (data is DueState) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'on_time': return DueState.onTime;
        case r'due_soon': return DueState.dueSoon;
        case r'overdue': return DueState.overdue;
        case r'answered': return DueState.answered;
        case r'no_deadline': return DueState.noDeadline;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DueStateTypeTransformer? _instance;
}

