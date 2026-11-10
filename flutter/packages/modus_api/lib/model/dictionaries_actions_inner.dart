//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DictionariesActionsInner {
  /// Returns a new [DictionariesActionsInner] instance.
  DictionariesActionsInner({
    required this.code,
    required this.label,
    this.from = const [],
    required this.to,
  });

  String code;

  String label;

  List<AppealStatus> from;

  AppealStatus? to;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DictionariesActionsInner &&
    other.code == code &&
    other.label == label &&
    _deepEquality.equals(other.from, from) &&
    other.to == to;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (label.hashCode) +
    (from.hashCode) +
    (to == null ? 0 : to!.hashCode);

  @override
  String toString() => 'DictionariesActionsInner[code=$code, label=$label, from=$from, to=$to]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'label'] = this.label;
      json[r'from'] = this.from;
    if (this.to != null) {
      json[r'to'] = this.to;
    } else {
      json[r'to'] = null;
    }
    return json;
  }

  /// Returns a new [DictionariesActionsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DictionariesActionsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'code'), 'Required key "DictionariesActionsInner[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "DictionariesActionsInner[code]" has a null value in JSON.');
        assert(json.containsKey(r'label'), 'Required key "DictionariesActionsInner[label]" is missing from JSON.');
        assert(json[r'label'] != null, 'Required key "DictionariesActionsInner[label]" has a null value in JSON.');
        assert(json.containsKey(r'from'), 'Required key "DictionariesActionsInner[from]" is missing from JSON.');
        assert(json[r'from'] != null, 'Required key "DictionariesActionsInner[from]" has a null value in JSON.');
        assert(json.containsKey(r'to'), 'Required key "DictionariesActionsInner[to]" is missing from JSON.');
        return true;
      }());

      return DictionariesActionsInner(
        code: mapValueOfType<String>(json, r'code')!,
        label: mapValueOfType<String>(json, r'label')!,
        from: AppealStatus.listFromJson(json[r'from']),
        to: AppealStatus.fromJson(json[r'to']),
      );
    }
    return null;
  }

  static List<DictionariesActionsInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DictionariesActionsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DictionariesActionsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DictionariesActionsInner> mapFromJson(dynamic json) {
    final map = <String, DictionariesActionsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DictionariesActionsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DictionariesActionsInner-objects as value to a dart map
  static Map<String, List<DictionariesActionsInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DictionariesActionsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DictionariesActionsInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'label',
    'from',
    'to',
  };
}

