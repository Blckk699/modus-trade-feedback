//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AppealRef {
  /// Returns a new [AppealRef] instance.
  AppealRef({
    required this.id,
    required this.number,
    required this.summary,
    required this.status,
    required this.type,
  });

  int id;

  String number;

  String? summary;

  AppealStatus status;

  AppealType type;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppealRef &&
    other.id == id &&
    other.number == number &&
    other.summary == summary &&
    other.status == status &&
    other.type == type;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (number.hashCode) +
    (summary == null ? 0 : summary!.hashCode) +
    (status.hashCode) +
    (type.hashCode);

  @override
  String toString() => 'AppealRef[id=$id, number=$number, summary=$summary, status=$status, type=$type]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'number'] = this.number;
    if (this.summary != null) {
      json[r'summary'] = this.summary;
    } else {
      json[r'summary'] = null;
    }
      json[r'status'] = this.status;
      json[r'type'] = this.type;
    return json;
  }

  /// Returns a new [AppealRef] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppealRef? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "AppealRef[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "AppealRef[id]" has a null value in JSON.');
        assert(json.containsKey(r'number'), 'Required key "AppealRef[number]" is missing from JSON.');
        assert(json[r'number'] != null, 'Required key "AppealRef[number]" has a null value in JSON.');
        assert(json.containsKey(r'summary'), 'Required key "AppealRef[summary]" is missing from JSON.');
        assert(json.containsKey(r'status'), 'Required key "AppealRef[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "AppealRef[status]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "AppealRef[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "AppealRef[type]" has a null value in JSON.');
        return true;
      }());

      return AppealRef(
        id: mapValueOfType<int>(json, r'id')!,
        number: mapValueOfType<String>(json, r'number')!,
        summary: mapValueOfType<String>(json, r'summary'),
        status: AppealStatus.fromJson(json[r'status'])!,
        type: AppealType.fromJson(json[r'type'])!,
      );
    }
    return null;
  }

  static List<AppealRef> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealRef>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealRef.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppealRef> mapFromJson(dynamic json) {
    final map = <String, AppealRef>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppealRef.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppealRef-objects as value to a dart map
  static Map<String, List<AppealRef>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AppealRef>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppealRef.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'number',
    'summary',
    'status',
    'type',
  };
}

