//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MeetingDraftUpdate {
  /// Returns a new [MeetingDraftUpdate] instance.
  MeetingDraftUpdate({
    this.type,
    this.categoryId,
    this.priority,
    this.summary,
    this.text,
    this.proposedSolution,
    this.authorId,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  AppealType? type;

  int? categoryId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Priority? priority;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? summary;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? text;

  String? proposedSolution;

  int? authorId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MeetingDraftUpdate &&
    other.type == type &&
    other.categoryId == categoryId &&
    other.priority == priority &&
    other.summary == summary &&
    other.text == text &&
    other.proposedSolution == proposedSolution &&
    other.authorId == authorId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type == null ? 0 : type!.hashCode) +
    (categoryId == null ? 0 : categoryId!.hashCode) +
    (priority == null ? 0 : priority!.hashCode) +
    (summary == null ? 0 : summary!.hashCode) +
    (text == null ? 0 : text!.hashCode) +
    (proposedSolution == null ? 0 : proposedSolution!.hashCode) +
    (authorId == null ? 0 : authorId!.hashCode);

  @override
  String toString() => 'MeetingDraftUpdate[type=$type, categoryId=$categoryId, priority=$priority, summary=$summary, text=$text, proposedSolution=$proposedSolution, authorId=$authorId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.categoryId != null) {
      json[r'category_id'] = this.categoryId;
    } else {
      json[r'category_id'] = null;
    }
    if (this.priority != null) {
      json[r'priority'] = this.priority;
    } else {
      json[r'priority'] = null;
    }
    if (this.summary != null) {
      json[r'summary'] = this.summary;
    } else {
      json[r'summary'] = null;
    }
    if (this.text != null) {
      json[r'text'] = this.text;
    } else {
      json[r'text'] = null;
    }
    if (this.proposedSolution != null) {
      json[r'proposed_solution'] = this.proposedSolution;
    } else {
      json[r'proposed_solution'] = null;
    }
    if (this.authorId != null) {
      json[r'author_id'] = this.authorId;
    } else {
      json[r'author_id'] = null;
    }
    return json;
  }

  /// Returns a new [MeetingDraftUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MeetingDraftUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return MeetingDraftUpdate(
        type: AppealType.fromJson(json[r'type']),
        categoryId: mapValueOfType<int>(json, r'category_id'),
        priority: Priority.fromJson(json[r'priority']),
        summary: mapValueOfType<String>(json, r'summary'),
        text: mapValueOfType<String>(json, r'text'),
        proposedSolution: mapValueOfType<String>(json, r'proposed_solution'),
        authorId: mapValueOfType<int>(json, r'author_id'),
      );
    }
    return null;
  }

  static List<MeetingDraftUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MeetingDraftUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeetingDraftUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MeetingDraftUpdate> mapFromJson(dynamic json) {
    final map = <String, MeetingDraftUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MeetingDraftUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MeetingDraftUpdate-objects as value to a dart map
  static Map<String, List<MeetingDraftUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MeetingDraftUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MeetingDraftUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

