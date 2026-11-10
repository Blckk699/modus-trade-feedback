//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MergeAppealRequest {
  /// Returns a new [MergeAppealRequest] instance.
  MergeAppealRequest({
    required this.mainAppealId,
  });

  int mainAppealId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MergeAppealRequest &&
    other.mainAppealId == mainAppealId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (mainAppealId.hashCode);

  @override
  String toString() => 'MergeAppealRequest[mainAppealId=$mainAppealId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'main_appeal_id'] = this.mainAppealId;
    return json;
  }

  /// Returns a new [MergeAppealRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MergeAppealRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'main_appeal_id'), 'Required key "MergeAppealRequest[main_appeal_id]" is missing from JSON.');
        assert(json[r'main_appeal_id'] != null, 'Required key "MergeAppealRequest[main_appeal_id]" has a null value in JSON.');
        return true;
      }());

      return MergeAppealRequest(
        mainAppealId: mapValueOfType<int>(json, r'main_appeal_id')!,
      );
    }
    return null;
  }

  static List<MergeAppealRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MergeAppealRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MergeAppealRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MergeAppealRequest> mapFromJson(dynamic json) {
    final map = <String, MergeAppealRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MergeAppealRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MergeAppealRequest-objects as value to a dart map
  static Map<String, List<MergeAppealRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MergeAppealRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MergeAppealRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'main_appeal_id',
  };
}

