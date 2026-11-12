//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TemporaryPassword {
  /// Returns a new [TemporaryPassword] instance.
  TemporaryPassword({
    required this.temporaryPassword,
  });

  /// Показывается один раз
  String temporaryPassword;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TemporaryPassword &&
    other.temporaryPassword == temporaryPassword;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (temporaryPassword.hashCode);

  @override
  String toString() => 'TemporaryPassword[temporaryPassword=$temporaryPassword]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'temporary_password'] = this.temporaryPassword;
    return json;
  }

  /// Returns a new [TemporaryPassword] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TemporaryPassword? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'temporary_password'), 'Required key "TemporaryPassword[temporary_password]" is missing from JSON.');
        assert(json[r'temporary_password'] != null, 'Required key "TemporaryPassword[temporary_password]" has a null value in JSON.');
        return true;
      }());

      return TemporaryPassword(
        temporaryPassword: mapValueOfType<String>(json, r'temporary_password')!,
      );
    }
    return null;
  }

  static List<TemporaryPassword> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TemporaryPassword>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TemporaryPassword.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TemporaryPassword> mapFromJson(dynamic json) {
    final map = <String, TemporaryPassword>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TemporaryPassword.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TemporaryPassword-objects as value to a dart map
  static Map<String, List<TemporaryPassword>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TemporaryPassword>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TemporaryPassword.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'temporary_password',
  };
}

