//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuthMethods {
  /// Returns a new [AuthMethods] instance.
  AuthMethods({
    required this.bitrix24,
  });

  /// Вход через Битрикс24 настроен на сервере
  bool bitrix24;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuthMethods &&
    other.bitrix24 == bitrix24;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (bitrix24.hashCode);

  @override
  String toString() => 'AuthMethods[bitrix24=$bitrix24]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'bitrix24'] = this.bitrix24;
    return json;
  }

  /// Returns a new [AuthMethods] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuthMethods? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'bitrix24'), 'Required key "AuthMethods[bitrix24]" is missing from JSON.');
        assert(json[r'bitrix24'] != null, 'Required key "AuthMethods[bitrix24]" has a null value in JSON.');
        return true;
      }());

      return AuthMethods(
        bitrix24: mapValueOfType<bool>(json, r'bitrix24')!,
      );
    }
    return null;
  }

  static List<AuthMethods> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuthMethods>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuthMethods.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuthMethods> mapFromJson(dynamic json) {
    final map = <String, AuthMethods>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuthMethods.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuthMethods-objects as value to a dart map
  static Map<String, List<AuthMethods>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuthMethods>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuthMethods.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'bitrix24',
  };
}

