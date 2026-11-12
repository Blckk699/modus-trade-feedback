//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Роль, которую можно выдать по заявке или приглашению — любая, кроме `owner`
enum AssignableRole {
  employee._(r'employee'),
  head._(r'head'),
  admin._(r'admin'),
  ;

  /// Instantiate a new enum with the provided value.
  const AssignableRole._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AssignableRole] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AssignableRole? fromJson(dynamic value) => AssignableRoleTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AssignableRole]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AssignableRole> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AssignableRole>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssignableRole.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AssignableRole] to String,
/// and [decode] dynamic data back to [AssignableRole].
class AssignableRoleTypeTransformer {
  factory AssignableRoleTypeTransformer() => _instance ??= const AssignableRoleTypeTransformer._();

  const AssignableRoleTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(AssignableRole data) => data._value;

  /// Returns the instance of [AssignableRole] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AssignableRole? decode(dynamic data, {bool allowNull = true}) {
    if (data is AssignableRole) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'employee': return AssignableRole.employee;
        case r'head': return AssignableRole.head;
        case r'admin': return AssignableRole.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AssignableRoleTypeTransformer? _instance;
}

