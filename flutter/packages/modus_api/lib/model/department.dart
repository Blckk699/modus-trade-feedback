//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Department {
  /// Returns a new [Department] instance.
  Department({
    required this.id,
    required this.name,
    required this.head,
  });

  int id;

  String name;

  UserBrief? head;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Department &&
    other.id == id &&
    other.name == name &&
    other.head == head;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (head == null ? 0 : head!.hashCode);

  @override
  String toString() => 'Department[id=$id, name=$name, head=$head]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
    if (this.head != null) {
      json[r'head'] = this.head;
    } else {
      json[r'head'] = null;
    }
    return json;
  }

  /// Returns a new [Department] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Department? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Department[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Department[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "Department[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "Department[name]" has a null value in JSON.');
        assert(json.containsKey(r'head'), 'Required key "Department[head]" is missing from JSON.');
        return true;
      }());

      return Department(
        id: mapValueOfType<int>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        head: UserBrief.fromJson(json[r'head']),
      );
    }
    return null;
  }

  static List<Department> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Department>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Department.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Department> mapFromJson(dynamic json) {
    final map = <String, Department>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Department.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Department-objects as value to a dart map
  static Map<String, List<Department>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Department>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Department.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'head',
  };
}

