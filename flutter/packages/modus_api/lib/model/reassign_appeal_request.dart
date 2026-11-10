//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ReassignAppealRequest {
  /// Returns a new [ReassignAppealRequest] instance.
  ReassignAppealRequest({
    required this.assigneeId,
    required this.reason,
  });

  int assigneeId;

  String reason;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ReassignAppealRequest &&
    other.assigneeId == assigneeId &&
    other.reason == reason;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (assigneeId.hashCode) +
    (reason.hashCode);

  @override
  String toString() => 'ReassignAppealRequest[assigneeId=$assigneeId, reason=$reason]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'assignee_id'] = this.assigneeId;
      json[r'reason'] = this.reason;
    return json;
  }

  /// Returns a new [ReassignAppealRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ReassignAppealRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'assignee_id'), 'Required key "ReassignAppealRequest[assignee_id]" is missing from JSON.');
        assert(json[r'assignee_id'] != null, 'Required key "ReassignAppealRequest[assignee_id]" has a null value in JSON.');
        assert(json.containsKey(r'reason'), 'Required key "ReassignAppealRequest[reason]" is missing from JSON.');
        assert(json[r'reason'] != null, 'Required key "ReassignAppealRequest[reason]" has a null value in JSON.');
        return true;
      }());

      return ReassignAppealRequest(
        assigneeId: mapValueOfType<int>(json, r'assignee_id')!,
        reason: mapValueOfType<String>(json, r'reason')!,
      );
    }
    return null;
  }

  static List<ReassignAppealRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ReassignAppealRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ReassignAppealRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ReassignAppealRequest> mapFromJson(dynamic json) {
    final map = <String, ReassignAppealRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ReassignAppealRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ReassignAppealRequest-objects as value to a dart map
  static Map<String, List<ReassignAppealRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ReassignAppealRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ReassignAppealRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'assignee_id',
    'reason',
  };
}

