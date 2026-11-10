//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DiscussionCreate {
  /// Returns a new [DiscussionCreate] instance.
  DiscussionCreate({
    required this.publicText,
    required this.deadline,
  });

  /// Публичная формулировка вопроса
  String publicText;

  DateTime deadline;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DiscussionCreate &&
    other.publicText == publicText &&
    other.deadline == deadline;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (publicText.hashCode) +
    (deadline.hashCode);

  @override
  String toString() => 'DiscussionCreate[publicText=$publicText, deadline=$deadline]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'public_text'] = this.publicText;
      json[r'deadline'] = this.deadline.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [DiscussionCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DiscussionCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'public_text'), 'Required key "DiscussionCreate[public_text]" is missing from JSON.');
        assert(json[r'public_text'] != null, 'Required key "DiscussionCreate[public_text]" has a null value in JSON.');
        assert(json.containsKey(r'deadline'), 'Required key "DiscussionCreate[deadline]" is missing from JSON.');
        assert(json[r'deadline'] != null, 'Required key "DiscussionCreate[deadline]" has a null value in JSON.');
        return true;
      }());

      return DiscussionCreate(
        publicText: mapValueOfType<String>(json, r'public_text')!,
        deadline: mapDateTime(json, r'deadline', r'')!,
      );
    }
    return null;
  }

  static List<DiscussionCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DiscussionCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DiscussionCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DiscussionCreate> mapFromJson(dynamic json) {
    final map = <String, DiscussionCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DiscussionCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DiscussionCreate-objects as value to a dart map
  static Map<String, List<DiscussionCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DiscussionCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DiscussionCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'public_text',
    'deadline',
  };
}

