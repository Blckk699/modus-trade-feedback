//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AssigneeLoad {
  /// Returns a new [AssigneeLoad] instance.
  AssigneeLoad({
    required this.assignee,
    required this.openCount,
    required this.overdueCount,
    required this.avgFirstResponseHours,
  });

  UserBrief assignee;

  /// Открытых обращений (не в финальном статусе)
  int openCount;

  /// Из них с просроченным сроком первого ответа
  int overdueCount;

  double? avgFirstResponseHours;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AssigneeLoad &&
    other.assignee == assignee &&
    other.openCount == openCount &&
    other.overdueCount == overdueCount &&
    other.avgFirstResponseHours == avgFirstResponseHours;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (assignee.hashCode) +
    (openCount.hashCode) +
    (overdueCount.hashCode) +
    (avgFirstResponseHours == null ? 0 : avgFirstResponseHours!.hashCode);

  @override
  String toString() => 'AssigneeLoad[assignee=$assignee, openCount=$openCount, overdueCount=$overdueCount, avgFirstResponseHours=$avgFirstResponseHours]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'assignee'] = this.assignee;
      json[r'open_count'] = this.openCount;
      json[r'overdue_count'] = this.overdueCount;
    if (this.avgFirstResponseHours != null) {
      json[r'avg_first_response_hours'] = this.avgFirstResponseHours;
    } else {
      json[r'avg_first_response_hours'] = null;
    }
    return json;
  }

  /// Returns a new [AssigneeLoad] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AssigneeLoad? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'assignee'), 'Required key "AssigneeLoad[assignee]" is missing from JSON.');
        assert(json[r'assignee'] != null, 'Required key "AssigneeLoad[assignee]" has a null value in JSON.');
        assert(json.containsKey(r'open_count'), 'Required key "AssigneeLoad[open_count]" is missing from JSON.');
        assert(json[r'open_count'] != null, 'Required key "AssigneeLoad[open_count]" has a null value in JSON.');
        assert(json.containsKey(r'overdue_count'), 'Required key "AssigneeLoad[overdue_count]" is missing from JSON.');
        assert(json[r'overdue_count'] != null, 'Required key "AssigneeLoad[overdue_count]" has a null value in JSON.');
        assert(json.containsKey(r'avg_first_response_hours'), 'Required key "AssigneeLoad[avg_first_response_hours]" is missing from JSON.');
        return true;
      }());

      return AssigneeLoad(
        assignee: UserBrief.fromJson(json[r'assignee'])!,
        openCount: mapValueOfType<int>(json, r'open_count')!,
        overdueCount: mapValueOfType<int>(json, r'overdue_count')!,
        avgFirstResponseHours: mapValueOfType<double>(json, r'avg_first_response_hours'),
      );
    }
    return null;
  }

  static List<AssigneeLoad> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AssigneeLoad>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssigneeLoad.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AssigneeLoad> mapFromJson(dynamic json) {
    final map = <String, AssigneeLoad>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AssigneeLoad.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AssigneeLoad-objects as value to a dart map
  static Map<String, List<AssigneeLoad>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AssigneeLoad>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AssigneeLoad.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'assignee',
    'open_count',
    'overdue_count',
    'avg_first_response_hours',
  };
}

