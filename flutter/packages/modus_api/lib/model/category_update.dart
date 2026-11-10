//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CategoryUpdate {
  /// Returns a new [CategoryUpdate] instance.
  CategoryUpdate({
    this.name,
    this.departmentId,
    this.responsibleId,
    this.deputyId,
    this.isActive,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? departmentId;

  int? responsibleId;

  int? deputyId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isActive;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CategoryUpdate &&
    other.name == name &&
    other.departmentId == departmentId &&
    other.responsibleId == responsibleId &&
    other.deputyId == deputyId &&
    other.isActive == isActive;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (departmentId == null ? 0 : departmentId!.hashCode) +
    (responsibleId == null ? 0 : responsibleId!.hashCode) +
    (deputyId == null ? 0 : deputyId!.hashCode) +
    (isActive == null ? 0 : isActive!.hashCode);

  @override
  String toString() => 'CategoryUpdate[name=$name, departmentId=$departmentId, responsibleId=$responsibleId, deputyId=$deputyId, isActive=$isActive]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.departmentId != null) {
      json[r'department_id'] = this.departmentId;
    } else {
      json[r'department_id'] = null;
    }
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
    if (this.isActive != null) {
      json[r'is_active'] = this.isActive;
    } else {
      json[r'is_active'] = null;
    }
    return json;
  }

  /// Returns a new [CategoryUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CategoryUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return CategoryUpdate(
        name: mapValueOfType<String>(json, r'name'),
        departmentId: mapValueOfType<int>(json, r'department_id'),
        responsibleId: mapValueOfType<int>(json, r'responsible_id'),
        deputyId: mapValueOfType<int>(json, r'deputy_id'),
        isActive: mapValueOfType<bool>(json, r'is_active'),
      );
    }
    return null;
  }

  static List<CategoryUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CategoryUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CategoryUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CategoryUpdate> mapFromJson(dynamic json) {
    final map = <String, CategoryUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CategoryUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CategoryUpdate-objects as value to a dart map
  static Map<String, List<CategoryUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CategoryUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CategoryUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

