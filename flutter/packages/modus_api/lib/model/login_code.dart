//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LoginCode {
  /// Returns a new [LoginCode] instance.
  LoginCode({
    required this.code,
    required this.expiresAt,
    required this.ttlSeconds,
  });

  String code;

  DateTime expiresAt;

  int ttlSeconds;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LoginCode &&
    other.code == code &&
    other.expiresAt == expiresAt &&
    other.ttlSeconds == ttlSeconds;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (code.hashCode) +
    (expiresAt.hashCode) +
    (ttlSeconds.hashCode);

  @override
  String toString() => 'LoginCode[code=$code, expiresAt=$expiresAt, ttlSeconds=$ttlSeconds]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'code'] = this.code;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
      json[r'ttl_seconds'] = this.ttlSeconds;
    return json;
  }

  /// Returns a new [LoginCode] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LoginCode? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'code'), 'Required key "LoginCode[code]" is missing from JSON.');
        assert(json[r'code'] != null, 'Required key "LoginCode[code]" has a null value in JSON.');
        assert(json.containsKey(r'expires_at'), 'Required key "LoginCode[expires_at]" is missing from JSON.');
        assert(json[r'expires_at'] != null, 'Required key "LoginCode[expires_at]" has a null value in JSON.');
        assert(json.containsKey(r'ttl_seconds'), 'Required key "LoginCode[ttl_seconds]" is missing from JSON.');
        assert(json[r'ttl_seconds'] != null, 'Required key "LoginCode[ttl_seconds]" has a null value in JSON.');
        return true;
      }());

      return LoginCode(
        code: mapValueOfType<String>(json, r'code')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
        ttlSeconds: mapValueOfType<int>(json, r'ttl_seconds')!,
      );
    }
    return null;
  }

  static List<LoginCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LoginCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LoginCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LoginCode> mapFromJson(dynamic json) {
    final map = <String, LoginCode>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LoginCode.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LoginCode-objects as value to a dart map
  static Map<String, List<LoginCode>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LoginCode>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LoginCode.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'code',
    'expires_at',
    'ttl_seconds',
  };
}

