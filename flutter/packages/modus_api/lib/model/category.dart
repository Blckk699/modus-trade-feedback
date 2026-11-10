//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Category {
  /// Returns a new [Category] instance.
  Category({
    required this.id,
    required this.name,
    required this.department,
    required this.responsible,
    required this.deputy,
    required this.isActive,
  });

  int id;

  String name;

  DepartmentRef department;

  UserBrief? responsible;

  UserBrief? deputy;

  bool isActive;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Category &&
    other.id == id &&
    other.name == name &&
    other.department == department &&
    other.responsible == responsible &&
    other.deputy == deputy &&
    other.isActive == isActive;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (department.hashCode) +
    (responsible == null ? 0 : responsible!.hashCode) +
    (deputy == null ? 0 : deputy!.hashCode) +
    (isActive.hashCode);

  @override
  String toString() => 'Category[id=$id, name=$name, department=$department, responsible=$responsible, deputy=$deputy, isActive=$isActive]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'department'] = this.department;
    if (this.responsible != null) {
      json[r'responsible'] = this.responsible;
    } else {
      json[r'responsible'] = null;
    }
    if (this.deputy != null) {
      json[r'deputy'] = this.deputy;
    } else {
      json[r'deputy'] = null;
    }
      json[r'is_active'] = this.isActive;
    return json;
  }

  /// Returns a new [Category] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Category? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Category[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Category[id]" has a null value in JSON.');
        assert(json.containsKey(r'name'), 'Required key "Category[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "Category[name]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "Category[department]" is missing from JSON.');
        assert(json[r'department'] != null, 'Required key "Category[department]" has a null value in JSON.');
        assert(json.containsKey(r'responsible'), 'Required key "Category[responsible]" is missing from JSON.');
        assert(json.containsKey(r'deputy'), 'Required key "Category[deputy]" is missing from JSON.');
        assert(json.containsKey(r'is_active'), 'Required key "Category[is_active]" is missing from JSON.');
        assert(json[r'is_active'] != null, 'Required key "Category[is_active]" has a null value in JSON.');
        return true;
      }());

      return Category(
        id: mapValueOfType<int>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        department: DepartmentRef.fromJson(json[r'department'])!,
        responsible: UserBrief.fromJson(json[r'responsible']),
        deputy: UserBrief.fromJson(json[r'deputy']),
        isActive: mapValueOfType<bool>(json, r'is_active')!,
      );
    }
    return null;
  }

  static List<Category> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Category>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Category.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Category> mapFromJson(dynamic json) {
    final map = <String, Category>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Category.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Category-objects as value to a dart map
  static Map<String, List<Category>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Category>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Category.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'department',
    'responsible',
    'deputy',
    'is_active',
  };
}

