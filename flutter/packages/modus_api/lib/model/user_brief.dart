//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserBrief {
  /// Returns a new [UserBrief] instance.
  UserBrief({
    required this.id,
    required this.fullName,
    required this.role,
    required this.department,
  });

  int id;

  String fullName;

  Role role;

  DepartmentRef? department;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserBrief &&
    other.id == id &&
    other.fullName == fullName &&
    other.role == role &&
    other.department == department;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (fullName.hashCode) +
    (role.hashCode) +
    (department == null ? 0 : department!.hashCode);

  @override
  String toString() => 'UserBrief[id=$id, fullName=$fullName, role=$role, department=$department]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'full_name'] = this.fullName;
      json[r'role'] = this.role;
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
    return json;
  }

  /// Returns a new [UserBrief] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserBrief? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "UserBrief[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "UserBrief[id]" has a null value in JSON.');
        assert(json.containsKey(r'full_name'), 'Required key "UserBrief[full_name]" is missing from JSON.');
        assert(json[r'full_name'] != null, 'Required key "UserBrief[full_name]" has a null value in JSON.');
        assert(json.containsKey(r'role'), 'Required key "UserBrief[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "UserBrief[role]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "UserBrief[department]" is missing from JSON.');
        return true;
      }());

      return UserBrief(
        id: mapValueOfType<int>(json, r'id')!,
        fullName: mapValueOfType<String>(json, r'full_name')!,
        role: Role.fromJson(json[r'role'])!,
        department: DepartmentRef.fromJson(json[r'department']),
      );
    }
    return null;
  }

  static List<UserBrief> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserBrief>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserBrief.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserBrief> mapFromJson(dynamic json) {
    final map = <String, UserBrief>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserBrief.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserBrief-objects as value to a dart map
  static Map<String, List<UserBrief>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserBrief>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserBrief.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'full_name',
    'role',
    'department',
  };
}

