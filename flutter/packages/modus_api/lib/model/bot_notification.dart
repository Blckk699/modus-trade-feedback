//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BotNotification {
  /// Returns a new [BotNotification] instance.
  BotNotification({
    required this.id,
    required this.kind,
    required this.text,
    required this.appeal,
    required this.path,
    this.buttons = const [],
    required this.isRead,
    required this.createdAt,
    required this.recipient,
    required this.attempts,
  });

  int id;

  NotificationKind kind;

  /// Текст для Telegram (`parse_mode=HTML`) и для списка в клиенте
  String text;

  AppealRef? appeal;

  /// Маршрут клиента: `/appeals/{id}`, `/discussions/{id}`, `/analytics`. Бот передаёт его в Mini App через `startapp` (`/appeals/21` → `appeals_21`). 
  String? path;

  List<NotificationButton> buttons;

  bool isRead;

  DateTime createdAt;

  BotNotificationAllOfRecipient recipient;

  /// Сколько раз бот уже пытался доставить
  int attempts;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BotNotification &&
    other.id == id &&
    other.kind == kind &&
    other.text == text &&
    other.appeal == appeal &&
    other.path == path &&
    _deepEquality.equals(other.buttons, buttons) &&
    other.isRead == isRead &&
    other.createdAt == createdAt &&
    other.recipient == recipient &&
    other.attempts == attempts;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (kind.hashCode) +
    (text.hashCode) +
    (appeal == null ? 0 : appeal!.hashCode) +
    (path == null ? 0 : path!.hashCode) +
    (buttons.hashCode) +
    (isRead.hashCode) +
    (createdAt.hashCode) +
    (recipient.hashCode) +
    (attempts.hashCode);

  @override
  String toString() => 'BotNotification[id=$id, kind=$kind, text=$text, appeal=$appeal, path=$path, buttons=$buttons, isRead=$isRead, createdAt=$createdAt, recipient=$recipient, attempts=$attempts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'kind'] = this.kind;
      json[r'text'] = this.text;
    if (this.appeal != null) {
      json[r'appeal'] = this.appeal;
    } else {
      json[r'appeal'] = null;
    }
    if (this.path != null) {
      json[r'path'] = this.path;
    } else {
      json[r'path'] = null;
    }
      json[r'buttons'] = this.buttons;
      json[r'is_read'] = this.isRead;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'recipient'] = this.recipient;
      json[r'attempts'] = this.attempts;
    return json;
  }

  /// Returns a new [BotNotification] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BotNotification? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "BotNotification[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "BotNotification[id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "BotNotification[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "BotNotification[kind]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "BotNotification[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "BotNotification[text]" has a null value in JSON.');
        assert(json.containsKey(r'appeal'), 'Required key "BotNotification[appeal]" is missing from JSON.');
        assert(json.containsKey(r'path'), 'Required key "BotNotification[path]" is missing from JSON.');
        assert(json.containsKey(r'buttons'), 'Required key "BotNotification[buttons]" is missing from JSON.');
        assert(json[r'buttons'] != null, 'Required key "BotNotification[buttons]" has a null value in JSON.');
        assert(json.containsKey(r'is_read'), 'Required key "BotNotification[is_read]" is missing from JSON.');
        assert(json[r'is_read'] != null, 'Required key "BotNotification[is_read]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "BotNotification[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "BotNotification[created_at]" has a null value in JSON.');
        assert(json.containsKey(r'recipient'), 'Required key "BotNotification[recipient]" is missing from JSON.');
        assert(json[r'recipient'] != null, 'Required key "BotNotification[recipient]" has a null value in JSON.');
        assert(json.containsKey(r'attempts'), 'Required key "BotNotification[attempts]" is missing from JSON.');
        assert(json[r'attempts'] != null, 'Required key "BotNotification[attempts]" has a null value in JSON.');
        return true;
      }());

      return BotNotification(
        id: mapValueOfType<int>(json, r'id')!,
        kind: NotificationKind.fromJson(json[r'kind'])!,
        text: mapValueOfType<String>(json, r'text')!,
        appeal: AppealRef.fromJson(json[r'appeal']),
        path: mapValueOfType<String>(json, r'path'),
        buttons: NotificationButton.listFromJson(json[r'buttons']),
        isRead: mapValueOfType<bool>(json, r'is_read')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        recipient: BotNotificationAllOfRecipient.fromJson(json[r'recipient'])!,
        attempts: mapValueOfType<int>(json, r'attempts')!,
      );
    }
    return null;
  }

  static List<BotNotification> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BotNotification>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BotNotification.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BotNotification> mapFromJson(dynamic json) {
    final map = <String, BotNotification>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BotNotification.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BotNotification-objects as value to a dart map
  static Map<String, List<BotNotification>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BotNotification>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BotNotification.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'kind',
    'text',
    'appeal',
    'path',
    'buttons',
    'is_read',
    'created_at',
    'recipient',
    'attempts',
  };
}

