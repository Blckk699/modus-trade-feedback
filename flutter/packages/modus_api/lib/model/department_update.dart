//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DepartmentUpdate {
  /// Returns a new [DepartmentUpdate] instance.
  DepartmentUpdate({
    this.name,
    this.headId,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  int? headId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DepartmentUpdate &&
    other.name == name &&
    other.headId == headId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (headId == null ? 0 : headId!.hashCode);

  @override
  String toString() => 'DepartmentUpdate[name=$name, headId=$headId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.headId != null) {
      json[r'head_id'] = this.headId;
    } else {
      json[r'head_id'] = null;
    }
    return json;
  }

  /// Returns a new [DepartmentUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DepartmentUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DepartmentUpdate(
        name: mapValueOfType<String>(json, r'name'),
        headId: mapValueOfType<int>(json, r'head_id'),
      );
    }
    return null;
  }

  static List<DepartmentUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DepartmentUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DepartmentUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DepartmentUpdate> mapFromJson(dynamic json) {
    final map = <String, DepartmentUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DepartmentUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DepartmentUpdate-objects as value to a dart map
  static Map<String, List<DepartmentUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DepartmentUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DepartmentUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

