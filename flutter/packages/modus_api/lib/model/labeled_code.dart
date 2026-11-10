//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LabeledCode {
  /// Returns a new [LabeledCode] instance.
  LabeledCode({
    required this.code,
    required this.label,
  });

  String code;

  String label;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LabeledCode &&
    other.code == code &&
    other.label == label;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (label.hashCode);

  @override
  String toString() => 'LabeledCode[code=$code, label=$label]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'label'] = this.label;
    return json;
  }

  /// Returns a new [LabeledCode] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LabeledCode? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'code'), 'Required key "LabeledCode[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "LabeledCode[code]" has a null value in JSON.');
        assert(json.containsKey(r'label'), 'Required key "LabeledCode[label]" is missing from JSON.');
        assert(json[r'label'] != null, 'Required key "LabeledCode[label]" has a null value in JSON.');
        return true;
      }());

      return LabeledCode(
        code: mapValueOfType<String>(json, r'code')!,
        label: mapValueOfType<String>(json, r'label')!,
      );
    }
    return null;
  }

  static List<LabeledCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LabeledCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LabeledCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LabeledCode> mapFromJson(dynamic json) {
    final map = <String, LabeledCode>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LabeledCode.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LabeledCode-objects as value to a dart map
  static Map<String, List<LabeledCode>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LabeledCode>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LabeledCode.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'label',
  };
}

