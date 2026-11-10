//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AckNotificationRequest {
  /// Returns a new [AckNotificationRequest] instance.
  AckNotificationRequest({
    this.telegramMessageId,
  });

  /// ID отправленного сообщения — бот по нему узнаёт, на какой вопрос ответил пользователь (reply)
  int? telegramMessageId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AckNotificationRequest &&
    other.telegramMessageId == telegramMessageId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (telegramMessageId == null ? 0 : telegramMessageId!.hashCode);

  @override
  String toString() => 'AckNotificationRequest[telegramMessageId=$telegramMessageId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.telegramMessageId != null) {
      json[r'telegram_message_id'] = this.telegramMessageId;
    } else {
      json[r'telegram_message_id'] = null;
    }
    return json;
  }

  /// Returns a new [AckNotificationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AckNotificationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AckNotificationRequest(
        telegramMessageId: mapValueOfType<int>(json, r'telegram_message_id'),
      );
    }
    return null;
  }

  static List<AckNotificationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AckNotificationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AckNotificationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AckNotificationRequest> mapFromJson(dynamic json) {
    final map = <String, AckNotificationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AckNotificationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AckNotificationRequest-objects as value to a dart map
  static Map<String, List<AckNotificationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AckNotificationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AckNotificationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

