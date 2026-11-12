//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InviteAccept {
  /// Returns a new [InviteAccept] instance.
  InviteAccept({
    this.initData,
    this.telegramLogin,
    required this.token,
    this.fullName,
    this.telegramUsername,
  });

  /// `Telegram.WebApp.initData` без изменений
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? initData;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  TelegramWidgetLoginRequest? telegramLogin;

  String token;

  /// Имя, если его нет в приглашении (бот — из профиля Telegram)
  String? fullName;

  /// Только бот
  String? telegramUsername;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InviteAccept &&
    other.initData == initData &&
    other.telegramLogin == telegramLogin &&
    other.token == token &&
    other.fullName == fullName &&
    other.telegramUsername == telegramUsername;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (initData == null ? 0 : initData!.hashCode) +
    (telegramLogin == null ? 0 : telegramLogin!.hashCode) +
    (token.hashCode) +
    (fullName == null ? 0 : fullName!.hashCode) +
    (telegramUsername == null ? 0 : telegramUsername!.hashCode);

  @override
  String toString() => 'InviteAccept[initData=$initData, telegramLogin=$telegramLogin, token=$token, fullName=$fullName, telegramUsername=$telegramUsername]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.initData != null) {
      json[r'init_data'] = this.initData;
    } else {
      json[r'init_data'] = null;
    }
    if (this.telegramLogin != null) {
      json[r'telegram_login'] = this.telegramLogin;
    } else {
      json[r'telegram_login'] = null;
    }
      json[r'token'] = this.token;
    if (this.fullName != null) {
      json[r'full_name'] = this.fullName;
    } else {
      json[r'full_name'] = null;
    }
    if (this.telegramUsername != null) {
      json[r'telegram_username'] = this.telegramUsername;
    } else {
      json[r'telegram_username'] = null;
    }
    return json;
  }

  /// Returns a new [InviteAccept] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InviteAccept? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'token'), 'Required key "InviteAccept[token]" is missing from JSON.');
        assert(json[r'token'] != null, 'Required key "InviteAccept[token]" has a null value in JSON.');
        return true;
      }());

      return InviteAccept(
        initData: mapValueOfType<String>(json, r'init_data'),
        telegramLogin: TelegramWidgetLoginRequest.fromJson(json[r'telegram_login']),
        token: mapValueOfType<String>(json, r'token')!,
        fullName: mapValueOfType<String>(json, r'full_name'),
        telegramUsername: mapValueOfType<String>(json, r'telegram_username'),
      );
    }
    return null;
  }

  static List<InviteAccept> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InviteAccept>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InviteAccept.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InviteAccept> mapFromJson(dynamic json) {
    final map = <String, InviteAccept>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InviteAccept.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InviteAccept-objects as value to a dart map
  static Map<String, List<InviteAccept>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InviteAccept>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InviteAccept.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'token',
  };
}

