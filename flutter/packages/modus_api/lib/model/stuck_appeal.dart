//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StuckAppeal {
  /// Returns a new [StuckAppeal] instance.
  StuckAppeal({
    required this.appeal,
    required this.assignee,
    required this.daysOverdue,
    required this.escalationLevel,
  });

  AppealRef appeal;

  UserBrief? assignee;

  /// Рабочих дней просрочки
  int daysOverdue;

  int escalationLevel;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StuckAppeal &&
    other.appeal == appeal &&
    other.assignee == assignee &&
    other.daysOverdue == daysOverdue &&
    other.escalationLevel == escalationLevel;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (appeal.hashCode) +
    (assignee == null ? 0 : assignee!.hashCode) +
    (daysOverdue.hashCode) +
    (escalationLevel.hashCode);

  @override
  String toString() => 'StuckAppeal[appeal=$appeal, assignee=$assignee, daysOverdue=$daysOverdue, escalationLevel=$escalationLevel]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'appeal'] = this.appeal;
    if (this.assignee != null) {
      json[r'assignee'] = this.assignee;
    } else {
      json[r'assignee'] = null;
    }
      json[r'days_overdue'] = this.daysOverdue;
      json[r'escalation_level'] = this.escalationLevel;
    return json;
  }

  /// Returns a new [StuckAppeal] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StuckAppeal? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'appeal'), 'Required key "StuckAppeal[appeal]" is missing from JSON.');
        assert(json[r'appeal'] != null, 'Required key "StuckAppeal[appeal]" has a null value in JSON.');
        assert(json.containsKey(r'assignee'), 'Required key "StuckAppeal[assignee]" is missing from JSON.');
        assert(json.containsKey(r'days_overdue'), 'Required key "StuckAppeal[days_overdue]" is missing from JSON.');
        assert(json[r'days_overdue'] != null, 'Required key "StuckAppeal[days_overdue]" has a null value in JSON.');
        assert(json.containsKey(r'escalation_level'), 'Required key "StuckAppeal[escalation_level]" is missing from JSON.');
        assert(json[r'escalation_level'] != null, 'Required key "StuckAppeal[escalation_level]" has a null value in JSON.');
        return true;
      }());

      return StuckAppeal(
        appeal: AppealRef.fromJson(json[r'appeal'])!,
        assignee: UserBrief.fromJson(json[r'assignee']),
        daysOverdue: mapValueOfType<int>(json, r'days_overdue')!,
        escalationLevel: mapValueOfType<int>(json, r'escalation_level')!,
      );
    }
    return null;
  }

  static List<StuckAppeal> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StuckAppeal>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StuckAppeal.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StuckAppeal> mapFromJson(dynamic json) {
    final map = <String, StuckAppeal>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StuckAppeal.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StuckAppeal-objects as value to a dart map
  static Map<String, List<StuckAppeal>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StuckAppeal>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StuckAppeal.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'appeal',
    'assignee',
    'days_overdue',
    'escalation_level',
  };
}

