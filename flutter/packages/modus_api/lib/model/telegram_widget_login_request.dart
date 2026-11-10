//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TelegramWidgetLoginRequest {
  /// Returns a new [TelegramWidgetLoginRequest] instance.
  TelegramWidgetLoginRequest({
    required this.id,
    required this.firstName,
    this.lastName,
    this.username,
    this.photoUrl,
    required this.authDate,
    required this.hash,
  });

  int id;

  String firstName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? lastName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? username;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? photoUrl;

  int authDate;

  String hash;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TelegramWidgetLoginRequest &&
    other.id == id &&
    other.firstName == firstName &&
    other.lastName == lastName &&
    other.username == username &&
    other.photoUrl == photoUrl &&
    other.authDate == authDate &&
    other.hash == hash;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (firstName.hashCode) +
    (lastName == null ? 0 : lastName!.hashCode) +
    (username == null ? 0 : username!.hashCode) +
    (photoUrl == null ? 0 : photoUrl!.hashCode) +
    (authDate.hashCode) +
    (hash.hashCode);

  @override
  String toString() => 'TelegramWidgetLoginRequest[id=$id, firstName=$firstName, lastName=$lastName, username=$username, photoUrl=$photoUrl, authDate=$authDate, hash=$hash]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'first_name'] = this.firstName;
    if (this.lastName != null) {
      json[r'last_name'] = this.lastName;
    } else {
      json[r'last_name'] = null;
    }
    if (this.username != null) {
      json[r'username'] = this.username;
    } else {
      json[r'username'] = null;
    }
    if (this.photoUrl != null) {
      json[r'photo_url'] = this.photoUrl;
    } else {
      json[r'photo_url'] = null;
    }
      json[r'auth_date'] = this.authDate;
      json[r'hash'] = this.hash;
    return json;
  }

  /// Returns a new [TelegramWidgetLoginRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TelegramWidgetLoginRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "TelegramWidgetLoginRequest[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "TelegramWidgetLoginRequest[id]" has a null value in JSON.');
        assert(json.containsKey(r'first_name'), 'Required key "TelegramWidgetLoginRequest[first_name]" is missing from JSON.');
        assert(json[r'first_name'] != null, 'Required key "TelegramWidgetLoginRequest[first_name]" has a null value in JSON.');
        assert(json.containsKey(r'auth_date'), 'Required key "TelegramWidgetLoginRequest[auth_date]" is missing from JSON.');
        assert(json[r'auth_date'] != null, 'Required key "TelegramWidgetLoginRequest[auth_date]" has a null value in JSON.');
        assert(json.containsKey(r'hash'), 'Required key "TelegramWidgetLoginRequest[hash]" is missing from JSON.');
        assert(json[r'hash'] != null, 'Required key "TelegramWidgetLoginRequest[hash]" has a null value in JSON.');
        return true;
      }());

      return TelegramWidgetLoginRequest(
        id: mapValueOfType<int>(json, r'id')!,
        firstName: mapValueOfType<String>(json, r'first_name')!,
        lastName: mapValueOfType<String>(json, r'last_name'),
        username: mapValueOfType<String>(json, r'username'),
        photoUrl: mapValueOfType<String>(json, r'photo_url'),
        authDate: mapValueOfType<int>(json, r'auth_date')!,
        hash: mapValueOfType<String>(json, r'hash')!,
      );
    }
    return null;
  }

  static List<TelegramWidgetLoginRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TelegramWidgetLoginRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TelegramWidgetLoginRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TelegramWidgetLoginRequest> mapFromJson(dynamic json) {
    final map = <String, TelegramWidgetLoginRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TelegramWidgetLoginRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TelegramWidgetLoginRequest-objects as value to a dart map
  static Map<String, List<TelegramWidgetLoginRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TelegramWidgetLoginRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TelegramWidgetLoginRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'first_name',
    'auth_date',
    'hash',
  };
}

