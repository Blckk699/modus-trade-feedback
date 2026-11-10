//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// all — всё видимое (по умолчанию); mine — я автор или участник; assigned — я ответственный; department — обращения моего подразделения (руководитель); unassigned — без ответственного (администратор) 
enum AppealScope {
  all._(r'all'),
  mine._(r'mine'),
  assigned._(r'assigned'),
  department._(r'department'),
  unassigned._(r'unassigned'),
  ;

  /// Instantiate a new enum with the provided value.
  const AppealScope._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AppealScope] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AppealScope? fromJson(dynamic value) => AppealScopeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AppealScope]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AppealScope> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealScope>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealScope.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AppealScope] to String,
/// and [decode] dynamic data back to [AppealScope].
class AppealScopeTypeTransformer {
  factory AppealScopeTypeTransformer() => _instance ??= const AppealScopeTypeTransformer._();

  const AppealScopeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(AppealScope data) => data._value;

  /// Returns the instance of [AppealScope] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AppealScope? decode(dynamic data, {bool allowNull = true}) {
    if (data is AppealScope) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'all': return AppealScope.all;
        case r'mine': return AppealScope.mine;
        case r'assigned': return AppealScope.assigned;
        case r'department': return AppealScope.department;
        case r'unassigned': return AppealScope.unassigned;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AppealScopeTypeTransformer? _instance;
}

