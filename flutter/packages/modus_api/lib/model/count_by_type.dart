//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CountByType {
  /// Returns a new [CountByType] instance.
  CountByType({
    required this.type,
    required this.count,
  });

  AppealType type;

  int count;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CountByType &&
    other.type == type &&
    other.count == count;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (count.hashCode);

  @override
  String toString() => 'CountByType[type=$type, count=$count]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
      json[r'count'] = this.count;
    return json;
  }

  /// Returns a new [CountByType] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CountByType? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'type'), 'Required key "CountByType[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "CountByType[type]" has a null value in JSON.');
        assert(json.containsKey(r'count'), 'Required key "CountByType[count]" is missing from JSON.');
        assert(json[r'count'] != null, 'Required key "CountByType[count]" has a null value in JSON.');
        return true;
      }());

      return CountByType(
        type: AppealType.fromJson(json[r'type'])!,
        count: mapValueOfType<int>(json, r'count')!,
      );
    }
    return null;
  }

  static List<CountByType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CountByType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CountByType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CountByType> mapFromJson(dynamic json) {
    final map = <String, CountByType>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CountByType.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CountByType-objects as value to a dart map
  static Map<String, List<CountByType>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CountByType>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CountByType.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'count',
  };
}

