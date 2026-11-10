//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DepartmentWrite {
  /// Returns a new [DepartmentWrite] instance.
  DepartmentWrite({
    required this.name,
    this.headId,
  });

  String name;

  int? headId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DepartmentWrite &&
    other.name == name &&
    other.headId == headId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (headId == null ? 0 : headId!.hashCode);

  @override
  String toString() => 'DepartmentWrite[name=$name, headId=$headId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
    if (this.headId != null) {
      json[r'head_id'] = this.headId;
    } else {
      json[r'head_id'] = null;
    }
    return json;
  }

  /// Returns a new [DepartmentWrite] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DepartmentWrite? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "DepartmentWrite[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "DepartmentWrite[name]" has a null value in JSON.');
        return true;
      }());

      return DepartmentWrite(
        name: mapValueOfType<String>(json, r'name')!,
        headId: mapValueOfType<int>(json, r'head_id'),
      );
    }
    return null;
  }

  static List<DepartmentWrite> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DepartmentWrite>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DepartmentWrite.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DepartmentWrite> mapFromJson(dynamic json) {
    final map = <String, DepartmentWrite>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DepartmentWrite.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DepartmentWrite-objects as value to a dart map
  static Map<String, List<DepartmentWrite>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DepartmentWrite>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DepartmentWrite.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

