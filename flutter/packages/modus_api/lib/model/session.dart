//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Session {
  /// Returns a new [Session] instance.
  Session({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.user,
  });

  String accessToken;

  SessionTokenTypeEnum tokenType;

  DateTime expiresAt;

  Me user;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Session &&
    other.accessToken == accessToken &&
    other.tokenType == tokenType &&
    other.expiresAt == expiresAt &&
    other.user == user;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (accessToken.hashCode) +
    (tokenType.hashCode) +
    (expiresAt.hashCode) +
    (user.hashCode);

  @override
  String toString() => 'Session[accessToken=$accessToken, tokenType=$tokenType, expiresAt=$expiresAt, user=$user]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'access_token'] = this.accessToken;
      json[r'token_type'] = this.tokenType;
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
      json[r'user'] = this.user;
    return json;
  }

  /// Returns a new [Session] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Session? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'access_token'), 'Required key "Session[access_token]" is missing from JSON.');
        assert(json[r'access_token'] != null, 'Required key "Session[access_token]" has a null value in JSON.');
        assert(json.containsKey(r'token_type'), 'Required key "Session[token_type]" is missing from JSON.');
        assert(json[r'token_type'] != null, 'Required key "Session[token_type]" has a null value in JSON.');
        assert(json.containsKey(r'expires_at'), 'Required key "Session[expires_at]" is missing from JSON.');
        assert(json[r'expires_at'] != null, 'Required key "Session[expires_at]" has a null value in JSON.');
        assert(json.containsKey(r'user'), 'Required key "Session[user]" is missing from JSON.');
        assert(json[r'user'] != null, 'Required key "Session[user]" has a null value in JSON.');
        return true;
      }());

      return Session(
        accessToken: mapValueOfType<String>(json, r'access_token')!,
        tokenType: SessionTokenTypeEnum.fromJson(json[r'token_type'])!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
        user: Me.fromJson(json[r'user'])!,
      );
    }
    return null;
  }

  static List<Session> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Session>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Session.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Session> mapFromJson(dynamic json) {
    final map = <String, Session>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Session.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Session-objects as value to a dart map
  static Map<String, List<Session>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Session>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Session.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'access_token',
    'token_type',
    'expires_at',
    'user',
  };
}


enum SessionTokenTypeEnum {
  bearer._(r'bearer'),
  ;

  /// Instantiate a new enum with the provided value.
  const SessionTokenTypeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [SessionTokenTypeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static SessionTokenTypeEnum? fromJson(dynamic value) => SessionTokenTypeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [SessionTokenTypeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<SessionTokenTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SessionTokenTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SessionTokenTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [SessionTokenTypeEnum] to String,
/// and [decode] dynamic data back to [SessionTokenTypeEnum].
class SessionTokenTypeEnumTypeTransformer {
  factory SessionTokenTypeEnumTypeTransformer() => _instance ??= const SessionTokenTypeEnumTypeTransformer._();

  const SessionTokenTypeEnumTypeTransformer._();

  String encode(SessionTokenTypeEnum data) => data._value;

  /// Returns the instance of [SessionTokenTypeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  SessionTokenTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is SessionTokenTypeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'bearer': return SessionTokenTypeEnum.bearer;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static SessionTokenTypeEnumTypeTransformer? _instance;
}


