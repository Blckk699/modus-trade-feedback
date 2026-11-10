//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserUpdate {
  /// Returns a new [UserUpdate] instance.
  UserUpdate({
    this.fullName,
    this.position,
    this.role,
    this.departmentId,
    this.isAbsent,
    this.isDisabled,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fullName;

  String? position;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Role? role;

  int? departmentId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isAbsent;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isDisabled;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserUpdate &&
    other.fullName == fullName &&
    other.position == position &&
    other.role == role &&
    other.departmentId == departmentId &&
    other.isAbsent == isAbsent &&
    other.isDisabled == isDisabled;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fullName == null ? 0 : fullName!.hashCode) +
    (position == null ? 0 : position!.hashCode) +
    (role == null ? 0 : role!.hashCode) +
    (departmentId == null ? 0 : departmentId!.hashCode) +
    (isAbsent == null ? 0 : isAbsent!.hashCode) +
    (isDisabled == null ? 0 : isDisabled!.hashCode);

  @override
  String toString() => 'UserUpdate[fullName=$fullName, position=$position, role=$role, departmentId=$departmentId, isAbsent=$isAbsent, isDisabled=$isDisabled]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.fullName != null) {
      json[r'full_name'] = this.fullName;
    } else {
      json[r'full_name'] = null;
    }
    if (this.position != null) {
      json[r'position'] = this.position;
    } else {
      json[r'position'] = null;
    }
    if (this.role != null) {
      json[r'role'] = this.role;
    } else {
      json[r'role'] = null;
    }
    if (this.departmentId != null) {
      json[r'department_id'] = this.departmentId;
    } else {
      json[r'department_id'] = null;
    }
    if (this.isAbsent != null) {
      json[r'is_absent'] = this.isAbsent;
    } else {
      json[r'is_absent'] = null;
    }
    if (this.isDisabled != null) {
      json[r'is_disabled'] = this.isDisabled;
    } else {
      json[r'is_disabled'] = null;
    }
    return json;
  }

  /// Returns a new [UserUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UserUpdate(
        fullName: mapValueOfType<String>(json, r'full_name'),
        position: mapValueOfType<String>(json, r'position'),
        role: Role.fromJson(json[r'role']),
        departmentId: mapValueOfType<int>(json, r'department_id'),
        isAbsent: mapValueOfType<bool>(json, r'is_absent'),
        isDisabled: mapValueOfType<bool>(json, r'is_disabled'),
      );
    }
    return null;
  }

  static List<UserUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserUpdate> mapFromJson(dynamic json) {
    final map = <String, UserUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserUpdate-objects as value to a dart map
  static Map<String, List<UserUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

