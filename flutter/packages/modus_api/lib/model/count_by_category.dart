//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CountByCategory {
  /// Returns a new [CountByCategory] instance.
  CountByCategory({
    required this.category,
    required this.count,
  });

  /// null — без категории
  CategoryRef? category;

  int count;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CountByCategory &&
    other.category == category &&
    other.count == count;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (category == null ? 0 : category!.hashCode) +
    (count.hashCode);

  @override
  String toString() => 'CountByCategory[category=$category, count=$count]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
      json[r'count'] = this.count;
    return json;
  }

  /// Returns a new [CountByCategory] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CountByCategory? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'category'), 'Required key "CountByCategory[category]" is missing from JSON.');
        assert(json.containsKey(r'count'), 'Required key "CountByCategory[count]" is missing from JSON.');
        assert(json[r'count'] != null, 'Required key "CountByCategory[count]" has a null value in JSON.');
        return true;
      }());

      return CountByCategory(
        category: CategoryRef.fromJson(json[r'category']),
        count: mapValueOfType<int>(json, r'count')!,
      );
    }
    return null;
  }

  static List<CountByCategory> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CountByCategory>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CountByCategory.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CountByCategory> mapFromJson(dynamic json) {
    final map = <String, CountByCategory>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CountByCategory.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CountByCategory-objects as value to a dart map
  static Map<String, List<CountByCategory>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CountByCategory>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CountByCategory.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'category',
    'count',
  };
}

