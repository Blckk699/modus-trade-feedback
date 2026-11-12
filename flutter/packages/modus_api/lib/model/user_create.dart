//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserCreate {
  /// Returns a new [UserCreate] instance.
  UserCreate({
    this.telegramId,
    this.email,
    required this.fullName,
    this.position,
    required this.role,
    this.departmentId,
  });

  int? telegramId;

  String? email;

  String fullName;

  String? position;

  Role role;

  int? departmentId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserCreate &&
    other.telegramId == telegramId &&
    other.email == email &&
    other.fullName == fullName &&
    other.position == position &&
    other.role == role &&
    other.departmentId == departmentId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (telegramId == null ? 0 : telegramId!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (fullName.hashCode) +
    (position == null ? 0 : position!.hashCode) +
    (role.hashCode) +
    (departmentId == null ? 0 : departmentId!.hashCode);

  @override
  String toString() => 'UserCreate[telegramId=$telegramId, email=$email, fullName=$fullName, position=$position, role=$role, departmentId=$departmentId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.telegramId != null) {
      json[r'telegram_id'] = this.telegramId;
    } else {
      json[r'telegram_id'] = null;
    }
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
      json[r'full_name'] = this.fullName;
    if (this.position != null) {
      json[r'position'] = this.position;
    } else {
      json[r'position'] = null;
    }
      json[r'role'] = this.role;
    if (this.departmentId != null) {
      json[r'department_id'] = this.departmentId;
    } else {
      json[r'department_id'] = null;
    }
    return json;
  }

  /// Returns a new [UserCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'full_name'), 'Required key "UserCreate[full_name]" is missing from JSON.');
        assert(json[r'full_name'] != null, 'Required key "UserCreate[full_name]" has a null value in JSON.');
        assert(json.containsKey(r'role'), 'Required key "UserCreate[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "UserCreate[role]" has a null value in JSON.');
        return true;
      }());

      return UserCreate(
        telegramId: mapValueOfType<int>(json, r'telegram_id'),
        email: mapValueOfType<String>(json, r'email'),
        fullName: mapValueOfType<String>(json, r'full_name')!,
        position: mapValueOfType<String>(json, r'position'),
        role: Role.fromJson(json[r'role'])!,
        departmentId: mapValueOfType<int>(json, r'department_id'),
      );
    }
    return null;
  }

  static List<UserCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserCreate> mapFromJson(dynamic json) {
    final map = <String, UserCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserCreate-objects as value to a dart map
  static Map<String, List<UserCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'full_name',
    'role',
  };
}

