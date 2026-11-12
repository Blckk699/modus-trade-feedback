//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AccessRequestApprove {
  /// Returns a new [AccessRequestApprove] instance.
  AccessRequestApprove({
    this.role = AssignableRole.employee,
    this.departmentId,
    this.fullName,
    this.position,
  });

  AssignableRole role;

  /// Не передано — подразделение из заявки
  int? departmentId;

  /// Не передано — имя из заявки
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fullName;

  String? position;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AccessRequestApprove &&
    other.role == role &&
    other.departmentId == departmentId &&
    other.fullName == fullName &&
    other.position == position;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role.hashCode) +
    (departmentId == null ? 0 : departmentId!.hashCode) +
    (fullName == null ? 0 : fullName!.hashCode) +
    (position == null ? 0 : position!.hashCode);

  @override
  String toString() => 'AccessRequestApprove[role=$role, departmentId=$departmentId, fullName=$fullName, position=$position]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'role'] = this.role;
    if (this.departmentId != null) {
      json[r'department_id'] = this.departmentId;
    } else {
      json[r'department_id'] = null;
    }
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
    return json;
  }

  /// Returns a new [AccessRequestApprove] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AccessRequestApprove? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AccessRequestApprove(
        role: AssignableRole.fromJson(json[r'role']) ?? AssignableRole.employee,
        departmentId: mapValueOfType<int>(json, r'department_id'),
        fullName: mapValueOfType<String>(json, r'full_name'),
        position: mapValueOfType<String>(json, r'position'),
      );
    }
    return null;
  }

  static List<AccessRequestApprove> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AccessRequestApprove>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AccessRequestApprove.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AccessRequestApprove> mapFromJson(dynamic json) {
    final map = <String, AccessRequestApprove>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AccessRequestApprove.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AccessRequestApprove-objects as value to a dart map
  static Map<String, List<AccessRequestApprove>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AccessRequestApprove>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AccessRequestApprove.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

