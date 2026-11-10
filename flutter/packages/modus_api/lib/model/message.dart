//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Message {
  /// Returns a new [Message] instance.
  Message({
    required this.id,
    required this.appealId,
    required this.author,
    required this.text,
    required this.isClarificationQuestion,
    required this.createdAt,
  });

  int id;

  int appealId;

  UserBrief author;

  String text;

  bool isClarificationQuestion;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Message &&
    other.id == id &&
    other.appealId == appealId &&
    other.author == author &&
    other.text == text &&
    other.isClarificationQuestion == isClarificationQuestion &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (appealId.hashCode) +
    (author.hashCode) +
    (text.hashCode) +
    (isClarificationQuestion.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Message[id=$id, appealId=$appealId, author=$author, text=$text, isClarificationQuestion=$isClarificationQuestion, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'appeal_id'] = this.appealId;
      json[r'author'] = this.author;
      json[r'text'] = this.text;
      json[r'is_clarification_question'] = this.isClarificationQuestion;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Message] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Message? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Message[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Message[id]" has a null value in JSON.');
        assert(json.containsKey(r'appeal_id'), 'Required key "Message[appeal_id]" is missing from JSON.');
        assert(json[r'appeal_id'] != null, 'Required key "Message[appeal_id]" has a null value in JSON.');
        assert(json.containsKey(r'author'), 'Required key "Message[author]" is missing from JSON.');
        assert(json[r'author'] != null, 'Required key "Message[author]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "Message[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "Message[text]" has a null value in JSON.');
        assert(json.containsKey(r'is_clarification_question'), 'Required key "Message[is_clarification_question]" is missing from JSON.');
        assert(json[r'is_clarification_question'] != null, 'Required key "Message[is_clarification_question]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "Message[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "Message[created_at]" has a null value in JSON.');
        return true;
      }());

      return Message(
        id: mapValueOfType<int>(json, r'id')!,
        appealId: mapValueOfType<int>(json, r'appeal_id')!,
        author: UserBrief.fromJson(json[r'author'])!,
        text: mapValueOfType<String>(json, r'text')!,
        isClarificationQuestion: mapValueOfType<bool>(json, r'is_clarification_question')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<Message> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Message>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Message.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Message> mapFromJson(dynamic json) {
    final map = <String, Message>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Message.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Message-objects as value to a dart map
  static Map<String, List<Message>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Message>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Message.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'appeal_id',
    'author',
    'text',
    'is_clarification_question',
    'created_at',
  };
}

