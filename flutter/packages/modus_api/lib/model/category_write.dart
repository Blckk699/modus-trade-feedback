//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CategoryWrite {
  /// Returns a new [CategoryWrite] instance.
  CategoryWrite({
    required this.name,
    required this.departmentId,
    this.responsibleId,
    this.deputyId,
  });

  String name;

  int departmentId;

  int? responsibleId;

  int? deputyId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CategoryWrite &&
    other.name == name &&
    other.departmentId == departmentId &&
    other.responsibleId == responsibleId &&
    other.deputyId == deputyId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (departmentId.hashCode) +
    (responsibleId == null ? 0 : responsibleId!.hashCode) +
    (deputyId == null ? 0 : deputyId!.hashCode);

  @override
  String toString() => 'CategoryWrite[name=$name, departmentId=$departmentId, responsibleId=$responsibleId, deputyId=$deputyId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'department_id'] = this.departmentId;
    if (this.responsibleId != null) {
      json[r'responsible_id'] = this.responsibleId;
    } else {
      json[r'responsible_id'] = null;
    }
    if (this.deputyId != null) {
      json[r'deputy_id'] = this.deputyId;
    } else {
      json[r'deputy_id'] = null;
    }
    return json;
  }

  /// Returns a new [CategoryWrite] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CategoryWrite? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "CategoryWrite[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "CategoryWrite[name]" has a null value in JSON.');
        assert(json.containsKey(r'department_id'), 'Required key "CategoryWrite[department_id]" is missing from JSON.');
        assert(json[r'department_id'] != null, 'Required key "CategoryWrite[department_id]" has a null value in JSON.');
        return true;
      }());

      return CategoryWrite(
        name: mapValueOfType<String>(json, r'name')!,
        departmentId: mapValueOfType<int>(json, r'department_id')!,
        responsibleId: mapValueOfType<int>(json, r'responsible_id'),
        deputyId: mapValueOfType<int>(json, r'deputy_id'),
      );
    }
    return null;
  }

  static List<CategoryWrite> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CategoryWrite>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CategoryWrite.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CategoryWrite> mapFromJson(dynamic json) {
    final map = <String, CategoryWrite>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CategoryWrite.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CategoryWrite-objects as value to a dart map
  static Map<String, List<CategoryWrite>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CategoryWrite>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CategoryWrite.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'department_id',
  };
}

