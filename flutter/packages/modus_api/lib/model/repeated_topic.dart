//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RepeatedTopic {
  /// Returns a new [RepeatedTopic] instance.
  RepeatedTopic({
    required this.appeal,
    required this.participantsCount,
  });

  AppealRef appeal;

  int participantsCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RepeatedTopic &&
    other.appeal == appeal &&
    other.participantsCount == participantsCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (appeal.hashCode) +
    (participantsCount.hashCode);

  @override
  String toString() => 'RepeatedTopic[appeal=$appeal, participantsCount=$participantsCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'appeal'] = this.appeal;
      json[r'participants_count'] = this.participantsCount;
    return json;
  }

  /// Returns a new [RepeatedTopic] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RepeatedTopic? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'appeal'), 'Required key "RepeatedTopic[appeal]" is missing from JSON.');
        assert(json[r'appeal'] != null, 'Required key "RepeatedTopic[appeal]" has a null value in JSON.');
        assert(json.containsKey(r'participants_count'), 'Required key "RepeatedTopic[participants_count]" is missing from JSON.');
        assert(json[r'participants_count'] != null, 'Required key "RepeatedTopic[participants_count]" has a null value in JSON.');
        return true;
      }());

      return RepeatedTopic(
        appeal: AppealRef.fromJson(json[r'appeal'])!,
        participantsCount: mapValueOfType<int>(json, r'participants_count')!,
      );
    }
    return null;
  }

  static List<RepeatedTopic> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RepeatedTopic>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RepeatedTopic.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RepeatedTopic> mapFromJson(dynamic json) {
    final map = <String, RepeatedTopic>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RepeatedTopic.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RepeatedTopic-objects as value to a dart map
  static Map<String, List<RepeatedTopic>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RepeatedTopic>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RepeatedTopic.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'appeal',
    'participants_count',
  };
}

