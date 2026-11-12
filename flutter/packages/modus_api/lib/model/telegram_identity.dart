//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TelegramIdentity {
  /// Returns a new [TelegramIdentity] instance.
  TelegramIdentity({
    this.initData,
    this.telegramLogin,
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

  @override
  bool operator ==(Object other) => identical(this, other) || other is TelegramIdentity &&
    other.initData == initData &&
    other.telegramLogin == telegramLogin;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (initData == null ? 0 : initData!.hashCode) +
    (telegramLogin == null ? 0 : telegramLogin!.hashCode);

  @override
  String toString() => 'TelegramIdentity[initData=$initData, telegramLogin=$telegramLogin]';

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
    return json;
  }

  /// Returns a new [TelegramIdentity] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TelegramIdentity? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TelegramIdentity(
        initData: mapValueOfType<String>(json, r'init_data'),
        telegramLogin: TelegramWidgetLoginRequest.fromJson(json[r'telegram_login']),
      );
    }
    return null;
  }

  static List<TelegramIdentity> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TelegramIdentity>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TelegramIdentity.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TelegramIdentity> mapFromJson(dynamic json) {
    final map = <String, TelegramIdentity>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TelegramIdentity.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TelegramIdentity-objects as value to a dart map
  static Map<String, List<TelegramIdentity>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TelegramIdentity>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TelegramIdentity.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

