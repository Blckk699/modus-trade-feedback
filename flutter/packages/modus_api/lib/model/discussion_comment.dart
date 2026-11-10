//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DiscussionComment {
  /// Returns a new [DiscussionComment] instance.
  DiscussionComment({
    required this.id,
    required this.discussionId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  int id;

  int discussionId;

  UserBrief author;

  String text;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DiscussionComment &&
    other.id == id &&
    other.discussionId == discussionId &&
    other.author == author &&
    other.text == text &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (discussionId.hashCode) +
    (author.hashCode) +
    (text.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'DiscussionComment[id=$id, discussionId=$discussionId, author=$author, text=$text, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'discussion_id'] = this.discussionId;
      json[r'author'] = this.author;
      json[r'text'] = this.text;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [DiscussionComment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DiscussionComment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "DiscussionComment[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "DiscussionComment[id]" has a null value in JSON.');
        assert(json.containsKey(r'discussion_id'), 'Required key "DiscussionComment[discussion_id]" is missing from JSON.');
        assert(json[r'discussion_id'] != null, 'Required key "DiscussionComment[discussion_id]" has a null value in JSON.');
        assert(json.containsKey(r'author'), 'Required key "DiscussionComment[author]" is missing from JSON.');
        assert(json[r'author'] != null, 'Required key "DiscussionComment[author]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "DiscussionComment[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "DiscussionComment[text]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "DiscussionComment[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "DiscussionComment[created_at]" has a null value in JSON.');
        return true;
      }());

      return DiscussionComment(
        id: mapValueOfType<int>(json, r'id')!,
        discussionId: mapValueOfType<int>(json, r'discussion_id')!,
        author: UserBrief.fromJson(json[r'author'])!,
        text: mapValueOfType<String>(json, r'text')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<DiscussionComment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DiscussionComment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DiscussionComment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DiscussionComment> mapFromJson(dynamic json) {
    final map = <String, DiscussionComment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DiscussionComment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DiscussionComment-objects as value to a dart map
  static Map<String, List<DiscussionComment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DiscussionComment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DiscussionComment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'discussion_id',
    'author',
    'text',
    'created_at',
  };
}

