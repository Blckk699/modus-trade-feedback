//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InvitePreview {
  /// Returns a new [InvitePreview] instance.
  InvitePreview({
    required this.role,
    required this.department,
    required this.fullName,
    required this.expiresAt,
  });

  AssignableRole role;

  DepartmentRef? department;

  String? fullName;

  DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InvitePreview &&
    other.role == role &&
    other.department == department &&
    other.fullName == fullName &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (fullName == null ? 0 : fullName!.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'InvitePreview[role=$role, department=$department, fullName=$fullName, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'role'] = this.role;
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
    if (this.fullName != null) {
      json[r'full_name'] = this.fullName;
    } else {
      json[r'full_name'] = null;
    }
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [InvitePreview] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InvitePreview? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'role'), 'Required key "InvitePreview[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "InvitePreview[role]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "InvitePreview[department]" is missing from JSON.');
        assert(json.containsKey(r'full_name'), 'Required key "InvitePreview[full_name]" is missing from JSON.');
        assert(json.containsKey(r'expires_at'), 'Required key "InvitePreview[expires_at]" is missing from JSON.');
        assert(json[r'expires_at'] != null, 'Required key "InvitePreview[expires_at]" has a null value in JSON.');
        return true;
      }());

      return InvitePreview(
        role: AssignableRole.fromJson(json[r'role'])!,
        department: DepartmentRef.fromJson(json[r'department']),
        fullName: mapValueOfType<String>(json, r'full_name'),
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
      );
    }
    return null;
  }

  static List<InvitePreview> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InvitePreview>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InvitePreview.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InvitePreview> mapFromJson(dynamic json) {
    final map = <String, InvitePreview>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InvitePreview.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InvitePreview-objects as value to a dart map
  static Map<String, List<InvitePreview>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InvitePreview>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InvitePreview.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'role',
    'department',
    'full_name',
    'expires_at',
  };
}

