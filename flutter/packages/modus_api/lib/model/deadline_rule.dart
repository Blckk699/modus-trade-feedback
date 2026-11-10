//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeadlineRule {
  /// Returns a new [DeadlineRule] instance.
  DeadlineRule({
    required this.priority,
    required this.businessDays,
  });

  Priority priority;

  /// Minimum value: 1
  /// Maximum value: 30
  int businessDays;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DeadlineRule &&
    other.priority == priority &&
    other.businessDays == businessDays;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (priority.hashCode) +
    (businessDays.hashCode);

  @override
  String toString() => 'DeadlineRule[priority=$priority, businessDays=$businessDays]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'priority'] = this.priority;
      json[r'business_days'] = this.businessDays;
    return json;
  }

  /// Returns a new [DeadlineRule] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeadlineRule? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'priority'), 'Required key "DeadlineRule[priority]" is missing from JSON.');
        assert(json[r'priority'] != null, 'Required key "DeadlineRule[priority]" has a null value in JSON.');
        assert(json.containsKey(r'business_days'), 'Required key "DeadlineRule[business_days]" is missing from JSON.');
        assert(json[r'business_days'] != null, 'Required key "DeadlineRule[business_days]" has a null value in JSON.');
        return true;
      }());

      return DeadlineRule(
        priority: Priority.fromJson(json[r'priority'])!,
        businessDays: mapValueOfType<int>(json, r'business_days')!,
      );
    }
    return null;
  }

  static List<DeadlineRule> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeadlineRule>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeadlineRule.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeadlineRule> mapFromJson(dynamic json) {
    final map = <String, DeadlineRule>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeadlineRule.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeadlineRule-objects as value to a dart map
  static Map<String, List<DeadlineRule>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DeadlineRule>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeadlineRule.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'priority',
    'business_days',
  };
}

