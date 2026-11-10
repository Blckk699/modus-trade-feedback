//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DictionariesStatusesInner {
  /// Returns a new [DictionariesStatusesInner] instance.
  DictionariesStatusesInner({
    required this.code,
    required this.label,
    required this.isFinal,
  });

  String code;

  String label;

  bool isFinal;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DictionariesStatusesInner &&
    other.code == code &&
    other.label == label &&
    other.isFinal == isFinal;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (label.hashCode) +
    (isFinal.hashCode);

  @override
  String toString() => 'DictionariesStatusesInner[code=$code, label=$label, isFinal=$isFinal]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'label'] = this.label;
      json[r'is_final'] = this.isFinal;
    return json;
  }

  /// Returns a new [DictionariesStatusesInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DictionariesStatusesInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'code'), 'Required key "DictionariesStatusesInner[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "DictionariesStatusesInner[code]" has a null value in JSON.');
        assert(json.containsKey(r'label'), 'Required key "DictionariesStatusesInner[label]" is missing from JSON.');
        assert(json[r'label'] != null, 'Required key "DictionariesStatusesInner[label]" has a null value in JSON.');
        assert(json.containsKey(r'is_final'), 'Required key "DictionariesStatusesInner[is_final]" is missing from JSON.');
        assert(json[r'is_final'] != null, 'Required key "DictionariesStatusesInner[is_final]" has a null value in JSON.');
        return true;
      }());

      return DictionariesStatusesInner(
        code: mapValueOfType<String>(json, r'code')!,
        label: mapValueOfType<String>(json, r'label')!,
        isFinal: mapValueOfType<bool>(json, r'is_final')!,
      );
    }
    return null;
  }

  static List<DictionariesStatusesInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DictionariesStatusesInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DictionariesStatusesInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DictionariesStatusesInner> mapFromJson(dynamic json) {
    final map = <String, DictionariesStatusesInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DictionariesStatusesInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DictionariesStatusesInner-objects as value to a dart map
  static Map<String, List<DictionariesStatusesInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DictionariesStatusesInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DictionariesStatusesInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'label',
    'is_final',
  };
}

