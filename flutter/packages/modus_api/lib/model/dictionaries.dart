//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Dictionaries {
  /// Returns a new [Dictionaries] instance.
  Dictionaries({
    this.appealTypes = const [],
    this.priorities = const [],
    this.statuses = const [],
    this.roles = const [],
    this.sources = const [],
    this.actions = const [],
    this.dueFilters = const [],
    required this.timezone,
  });

  List<LabeledCode> appealTypes;

  List<LabeledCode> priorities;

  List<DictionariesStatusesInner> statuses;

  List<LabeledCode> roles;

  List<LabeledCode> sources;

  /// Подписи кнопок и справочная таблица переходов. Доступность — только по `Appeal.allowed_actions`.
  List<DictionariesActionsInner> actions;

  List<LabeledCode> dueFilters;

  String timezone;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Dictionaries &&
    _deepEquality.equals(other.appealTypes, appealTypes) &&
    _deepEquality.equals(other.priorities, priorities) &&
    _deepEquality.equals(other.statuses, statuses) &&
    _deepEquality.equals(other.roles, roles) &&
    _deepEquality.equals(other.sources, sources) &&
    _deepEquality.equals(other.actions, actions) &&
    _deepEquality.equals(other.dueFilters, dueFilters) &&
    other.timezone == timezone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (appealTypes.hashCode) +
    (priorities.hashCode) +
    (statuses.hashCode) +
    (roles.hashCode) +
    (sources.hashCode) +
    (actions.hashCode) +
    (dueFilters.hashCode) +
    (timezone.hashCode);

  @override
  String toString() => 'Dictionaries[appealTypes=$appealTypes, priorities=$priorities, statuses=$statuses, roles=$roles, sources=$sources, actions=$actions, dueFilters=$dueFilters, timezone=$timezone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'appeal_types'] = this.appealTypes;
      json[r'priorities'] = this.priorities;
      json[r'statuses'] = this.statuses;
      json[r'roles'] = this.roles;
      json[r'sources'] = this.sources;
      json[r'actions'] = this.actions;
      json[r'due_filters'] = this.dueFilters;
      json[r'timezone'] = this.timezone;
    return json;
  }

  /// Returns a new [Dictionaries] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Dictionaries? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'appeal_types'), 'Required key "Dictionaries[appeal_types]" is missing from JSON.');
        assert(json[r'appeal_types'] != null, 'Required key "Dictionaries[appeal_types]" has a null value in JSON.');
        assert(json.containsKey(r'priorities'), 'Required key "Dictionaries[priorities]" is missing from JSON.');
        assert(json[r'priorities'] != null, 'Required key "Dictionaries[priorities]" has a null value in JSON.');
        assert(json.containsKey(r'statuses'), 'Required key "Dictionaries[statuses]" is missing from JSON.');
        assert(json[r'statuses'] != null, 'Required key "Dictionaries[statuses]" has a null value in JSON.');
        assert(json.containsKey(r'roles'), 'Required key "Dictionaries[roles]" is missing from JSON.');
        assert(json[r'roles'] != null, 'Required key "Dictionaries[roles]" has a null value in JSON.');
        assert(json.containsKey(r'sources'), 'Required key "Dictionaries[sources]" is missing from JSON.');
        assert(json[r'sources'] != null, 'Required key "Dictionaries[sources]" has a null value in JSON.');
        assert(json.containsKey(r'actions'), 'Required key "Dictionaries[actions]" is missing from JSON.');
        assert(json[r'actions'] != null, 'Required key "Dictionaries[actions]" has a null value in JSON.');
        assert(json.containsKey(r'due_filters'), 'Required key "Dictionaries[due_filters]" is missing from JSON.');
        assert(json[r'due_filters'] != null, 'Required key "Dictionaries[due_filters]" has a null value in JSON.');
        assert(json.containsKey(r'timezone'), 'Required key "Dictionaries[timezone]" is missing from JSON.');
        assert(json[r'timezone'] != null, 'Required key "Dictionaries[timezone]" has a null value in JSON.');
        return true;
      }());

      return Dictionaries(
        appealTypes: LabeledCode.listFromJson(json[r'appeal_types']),
        priorities: LabeledCode.listFromJson(json[r'priorities']),
        statuses: DictionariesStatusesInner.listFromJson(json[r'statuses']),
        roles: LabeledCode.listFromJson(json[r'roles']),
        sources: LabeledCode.listFromJson(json[r'sources']),
        actions: DictionariesActionsInner.listFromJson(json[r'actions']),
        dueFilters: LabeledCode.listFromJson(json[r'due_filters']),
        timezone: mapValueOfType<String>(json, r'timezone')!,
      );
    }
    return null;
  }

  static List<Dictionaries> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Dictionaries>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Dictionaries.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Dictionaries> mapFromJson(dynamic json) {
    final map = <String, Dictionaries>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Dictionaries.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Dictionaries-objects as value to a dart map
  static Map<String, List<Dictionaries>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Dictionaries>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Dictionaries.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'appeal_types',
    'priorities',
    'statuses',
    'roles',
    'sources',
    'actions',
    'due_filters',
    'timezone',
  };
}

