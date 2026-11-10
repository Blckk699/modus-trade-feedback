//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotificationButton {
  /// Returns a new [NotificationButton] instance.
  NotificationButton({
    required this.type,
    required this.text,
    required this.appealId,
    required this.discussionId,
  });

  NotificationButtonType type;

  String text;

  int? appealId;

  int? discussionId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationButton &&
    other.type == type &&
    other.text == text &&
    other.appealId == appealId &&
    other.discussionId == discussionId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (text.hashCode) +
    (appealId == null ? 0 : appealId!.hashCode) +
    (discussionId == null ? 0 : discussionId!.hashCode);

  @override
  String toString() => 'NotificationButton[type=$type, text=$text, appealId=$appealId, discussionId=$discussionId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
      json[r'text'] = this.text;
    if (this.appealId != null) {
      json[r'appeal_id'] = this.appealId;
    } else {
      json[r'appeal_id'] = null;
    }
    if (this.discussionId != null) {
      json[r'discussion_id'] = this.discussionId;
    } else {
      json[r'discussion_id'] = null;
    }
    return json;
  }

  /// Returns a new [NotificationButton] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationButton? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'type'), 'Required key "NotificationButton[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "NotificationButton[type]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "NotificationButton[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "NotificationButton[text]" has a null value in JSON.');
        assert(json.containsKey(r'appeal_id'), 'Required key "NotificationButton[appeal_id]" is missing from JSON.');
        assert(json.containsKey(r'discussion_id'), 'Required key "NotificationButton[discussion_id]" is missing from JSON.');
        return true;
      }());

      return NotificationButton(
        type: NotificationButtonType.fromJson(json[r'type'])!,
        text: mapValueOfType<String>(json, r'text')!,
        appealId: mapValueOfType<int>(json, r'appeal_id'),
        discussionId: mapValueOfType<int>(json, r'discussion_id'),
      );
    }
    return null;
  }

  static List<NotificationButton> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationButton>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationButton.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationButton> mapFromJson(dynamic json) {
    final map = <String, NotificationButton>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationButton.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationButton-objects as value to a dart map
  static Map<String, List<NotificationButton>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationButton>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationButton.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'text',
    'appeal_id',
    'discussion_id',
  };
}

