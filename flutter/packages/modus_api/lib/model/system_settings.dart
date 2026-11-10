//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SystemSettings {
  /// Returns a new [SystemSettings] instance.
  SystemSettings({
    required this.digestTime,
    required this.timezone,
  });

  /// Время утренней сводки, ЧЧ:ММ по часовому поясу системы
  String digestTime;

  /// Часовой пояс системы, задаётся окружением; только чтение
  String timezone;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SystemSettings &&
    other.digestTime == digestTime &&
    other.timezone == timezone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (digestTime.hashCode) +
    (timezone.hashCode);

  @override
  String toString() => 'SystemSettings[digestTime=$digestTime, timezone=$timezone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'digest_time'] = this.digestTime;
      json[r'timezone'] = this.timezone;
    return json;
  }

  /// Returns a new [SystemSettings] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SystemSettings? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'digest_time'), 'Required key "SystemSettings[digest_time]" is missing from JSON.');
        assert(json[r'digest_time'] != null, 'Required key "SystemSettings[digest_time]" has a null value in JSON.');
        assert(json.containsKey(r'timezone'), 'Required key "SystemSettings[timezone]" is missing from JSON.');
        assert(json[r'timezone'] != null, 'Required key "SystemSettings[timezone]" has a null value in JSON.');
        return true;
      }());

      return SystemSettings(
        digestTime: mapValueOfType<String>(json, r'digest_time')!,
        timezone: mapValueOfType<String>(json, r'timezone')!,
      );
    }
    return null;
  }

  static List<SystemSettings> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SystemSettings>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SystemSettings.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SystemSettings> mapFromJson(dynamic json) {
    final map = <String, SystemSettings>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SystemSettings.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SystemSettings-objects as value to a dart map
  static Map<String, List<SystemSettings>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SystemSettings>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SystemSettings.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'digest_time',
    'timezone',
  };
}

