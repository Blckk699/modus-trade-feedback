//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AccessRequestSubmit {
  /// Returns a new [AccessRequestSubmit] instance.
  AccessRequestSubmit({
    this.initData,
    this.telegramLogin,
    required this.fullName,
    this.departmentId,
    this.comment,
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

  /// По умолчанию клиент подставляет имя из профиля Telegram
  String fullName;

  /// Из `GET /access-requests/departments`
  int? departmentId;

  /// Должность или комментарий
  String? comment;

  /// Только бот (ник из профиля). Mini App и веб — ник берётся из подписанных данных
  String? telegramUsername;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AccessRequestSubmit &&
    other.initData == initData &&
    other.telegramLogin == telegramLogin &&
    other.fullName == fullName &&
    other.departmentId == departmentId &&
    other.comment == comment &&
    other.telegramUsername == telegramUsername;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (initData == null ? 0 : initData!.hashCode) +
    (telegramLogin == null ? 0 : telegramLogin!.hashCode) +
    (fullName.hashCode) +
    (departmentId == null ? 0 : departmentId!.hashCode) +
    (comment == null ? 0 : comment!.hashCode) +
    (telegramUsername == null ? 0 : telegramUsername!.hashCode);

  @override
  String toString() => 'AccessRequestSubmit[initData=$initData, telegramLogin=$telegramLogin, fullName=$fullName, departmentId=$departmentId, comment=$comment, telegramUsername=$telegramUsername]';

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
      json[r'full_name'] = this.fullName;
    if (this.departmentId != null) {
      json[r'department_id'] = this.departmentId;
    } else {
      json[r'department_id'] = null;
    }
    if (this.comment != null) {
      json[r'comment'] = this.comment;
    } else {
      json[r'comment'] = null;
    }
    if (this.telegramUsername != null) {
      json[r'telegram_username'] = this.telegramUsername;
    } else {
      json[r'telegram_username'] = null;
    }
    return json;
  }

  /// Returns a new [AccessRequestSubmit] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AccessRequestSubmit? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'full_name'), 'Required key "AccessRequestSubmit[full_name]" is missing from JSON.');
        assert(json[r'full_name'] != null, 'Required key "AccessRequestSubmit[full_name]" has a null value in JSON.');
        return true;
      }());

      return AccessRequestSubmit(
        initData: mapValueOfType<String>(json, r'init_data'),
        telegramLogin: TelegramWidgetLoginRequest.fromJson(json[r'telegram_login']),
        fullName: mapValueOfType<String>(json, r'full_name')!,
        departmentId: mapValueOfType<int>(json, r'department_id'),
        comment: mapValueOfType<String>(json, r'comment'),
        telegramUsername: mapValueOfType<String>(json, r'telegram_username'),
      );
    }
    return null;
  }

  static List<AccessRequestSubmit> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AccessRequestSubmit>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AccessRequestSubmit.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AccessRequestSubmit> mapFromJson(dynamic json) {
    final map = <String, AccessRequestSubmit>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AccessRequestSubmit.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AccessRequestSubmit-objects as value to a dart map
  static Map<String, List<AccessRequestSubmit>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AccessRequestSubmit>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AccessRequestSubmit.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'full_name',
  };
}

