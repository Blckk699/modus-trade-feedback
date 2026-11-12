//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SessionToken {
  /// Returns a new [SessionToken] instance.
  SessionToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
  });

  String accessToken;

  SessionTokenTokenTypeEnum tokenType;

  DateTime expiresAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SessionToken &&
    other.accessToken == accessToken &&
    other.tokenType == tokenType &&
    other.expiresAt == expiresAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accessToken.hashCode) +
    (tokenType.hashCode) +
    (expiresAt.hashCode);

  @override
  String toString() => 'SessionToken[accessToken=$accessToken, tokenType=$tokenType, expiresAt=$expiresAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'access_token'] = this.accessToken;
      json[r'token_type'] = this.tokenType;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [SessionToken] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SessionToken? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'access_token'), 'Required key "SessionToken[access_token]" is missing from JSON.');
        assert(json[r'access_token'] != null, 'Required key "SessionToken[access_token]" has a null value in JSON.');
        assert(json.containsKey(r'token_type'), 'Required key "SessionToken[token_type]" is missing from JSON.');
        assert(json[r'token_type'] != null, 'Required key "SessionToken[token_type]" has a null value in JSON.');
        assert(json.containsKey(r'expires_at'), 'Required key "SessionToken[expires_at]" is missing from JSON.');
        assert(json[r'expires_at'] != null, 'Required key "SessionToken[expires_at]" has a null value in JSON.');
        return true;
      }());

      return SessionToken(
        accessToken: mapValueOfType<String>(json, r'access_token')!,
        tokenType: SessionTokenTokenTypeEnum.fromJson(json[r'token_type'])!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
      );
    }
    return null;
  }

  static List<SessionToken> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionToken>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionToken.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SessionToken> mapFromJson(dynamic json) {
    final map = <String, SessionToken>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SessionToken.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SessionToken-objects as value to a dart map
  static Map<String, List<SessionToken>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SessionToken>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SessionToken.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'access_token',
    'token_type',
    'expires_at',
  };
}


enum SessionTokenTokenTypeEnum {
  bearer._(r'bearer'),
  ;

  /// Instantiate a new enum with the provided value.
  const SessionTokenTokenTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SessionTokenTokenTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SessionTokenTokenTypeEnum? fromJson(dynamic value) => SessionTokenTokenTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SessionTokenTokenTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SessionTokenTokenTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionTokenTokenTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionTokenTokenTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SessionTokenTokenTypeEnum] to String,
/// and [decode] dynamic data back to [SessionTokenTokenTypeEnum].
class SessionTokenTokenTypeEnumTypeTransformer {
  factory SessionTokenTokenTypeEnumTypeTransformer() => _instance ??= const SessionTokenTokenTypeEnumTypeTransformer._();

  const SessionTokenTokenTypeEnumTypeTransformer._();

  String encode(SessionTokenTokenTypeEnum data) => data._value;

  /// Returns the instance of [SessionTokenTokenTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SessionTokenTokenTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is SessionTokenTokenTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'bearer': return SessionTokenTokenTypeEnum.bearer;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SessionTokenTokenTypeEnumTypeTransformer? _instance;
}


