//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InviteCreate {
  /// Returns a new [InviteCreate] instance.
  InviteCreate({
    required this.role,
    this.departmentId,
    this.fullName,
    this.expiresInDays = 7,
    this.maxUses = 1,
  });

  AssignableRole role;

  int? departmentId;

  /// Имя нового сотрудника; не задано — из профиля Telegram
  String? fullName;

  /// Minimum value: 1
  /// Maximum value: 30
  int expiresInDays;

  /// Minimum value: 1
  /// Maximum value: 100
  int maxUses;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InviteCreate &&
    other.role == role &&
    other.departmentId == departmentId &&
    other.fullName == fullName &&
    other.expiresInDays == expiresInDays &&
    other.maxUses == maxUses;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (role.hashCode) +
    (departmentId == null ? 0 : departmentId!.hashCode) +
    (fullName == null ? 0 : fullName!.hashCode) +
    (expiresInDays.hashCode) +
    (maxUses.hashCode);

  @override
  String toString() => 'InviteCreate[role=$role, departmentId=$departmentId, fullName=$fullName, expiresInDays=$expiresInDays, maxUses=$maxUses]';

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
      json[r'expires_in_days'] = this.expiresInDays;
      json[r'max_uses'] = this.maxUses;
    return json;
  }

  /// Returns a new [InviteCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InviteCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'role'), 'Required key "InviteCreate[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "InviteCreate[role]" has a null value in JSON.');
        return true;
      }());

      return InviteCreate(
        role: AssignableRole.fromJson(json[r'role'])!,
        departmentId: mapValueOfType<int>(json, r'department_id'),
        fullName: mapValueOfType<String>(json, r'full_name'),
        expiresInDays: mapValueOfType<int>(json, r'expires_in_days') ?? 7,
        maxUses: mapValueOfType<int>(json, r'max_uses') ?? 1,
      );
    }
    return null;
  }

  static List<InviteCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InviteCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InviteCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InviteCreate> mapFromJson(dynamic json) {
    final map = <String, InviteCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InviteCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InviteCreate-objects as value to a dart map
  static Map<String, List<InviteCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InviteCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InviteCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'role',
  };
}

