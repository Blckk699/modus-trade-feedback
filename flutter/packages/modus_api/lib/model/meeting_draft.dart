//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MeetingDraft {
  /// Returns a new [MeetingDraft] instance.
  MeetingDraft({
    required this.id,
    required this.meetingId,
    required this.status,
    required this.type,
    required this.category,
    required this.priority,
    required this.summary,
    required this.text,
    required this.proposedSolution,
    required this.quote,
    required this.author,
    required this.appeal,
  });

  int id;

  int meetingId;

  MeetingDraftStatus status;

  AppealType type;

  CategoryRef? category;

  Priority priority;

  String summary;

  String text;

  String? proposedSolution;

  /// Цитата из расшифровки, на которой основан черновик
  String quote;

  /// Сотрудник-автор; null — автором станет загрузивший
  UserBrief? author;

  /// Созданное обращение после подтверждения
  AppealRef? appeal;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MeetingDraft &&
    other.id == id &&
    other.meetingId == meetingId &&
    other.status == status &&
    other.type == type &&
    other.category == category &&
    other.priority == priority &&
    other.summary == summary &&
    other.text == text &&
    other.proposedSolution == proposedSolution &&
    other.quote == quote &&
    other.author == author &&
    other.appeal == appeal;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (meetingId.hashCode) +
    (status.hashCode) +
    (type.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (priority.hashCode) +
    (summary.hashCode) +
    (text.hashCode) +
    (proposedSolution == null ? 0 : proposedSolution!.hashCode) +
    (quote.hashCode) +
    (author == null ? 0 : author!.hashCode) +
    (appeal == null ? 0 : appeal!.hashCode);

  @override
  String toString() => 'MeetingDraft[id=$id, meetingId=$meetingId, status=$status, type=$type, category=$category, priority=$priority, summary=$summary, text=$text, proposedSolution=$proposedSolution, quote=$quote, author=$author, appeal=$appeal]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'meeting_id'] = this.meetingId;
      json[r'status'] = this.status;
      json[r'type'] = this.type;
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
      json[r'priority'] = this.priority;
      json[r'summary'] = this.summary;
      json[r'text'] = this.text;
    if (this.proposedSolution != null) {
      json[r'proposed_solution'] = this.proposedSolution;
    } else {
      json[r'proposed_solution'] = null;
    }
      json[r'quote'] = this.quote;
    if (this.author != null) {
      json[r'author'] = this.author;
    } else {
      json[r'author'] = null;
    }
    if (this.appeal != null) {
      json[r'appeal'] = this.appeal;
    } else {
      json[r'appeal'] = null;
    }
    return json;
  }

  /// Returns a new [MeetingDraft] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MeetingDraft? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "MeetingDraft[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "MeetingDraft[id]" has a null value in JSON.');
        assert(json.containsKey(r'meeting_id'), 'Required key "MeetingDraft[meeting_id]" is missing from JSON.');
        assert(json[r'meeting_id'] != null, 'Required key "MeetingDraft[meeting_id]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "MeetingDraft[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "MeetingDraft[status]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "MeetingDraft[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "MeetingDraft[type]" has a null value in JSON.');
        assert(json.containsKey(r'category'), 'Required key "MeetingDraft[category]" is missing from JSON.');
        assert(json.containsKey(r'priority'), 'Required key "MeetingDraft[priority]" is missing from JSON.');
        assert(json[r'priority'] != null, 'Required key "MeetingDraft[priority]" has a null value in JSON.');
        assert(json.containsKey(r'summary'), 'Required key "MeetingDraft[summary]" is missing from JSON.');
        assert(json[r'summary'] != null, 'Required key "MeetingDraft[summary]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "MeetingDraft[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "MeetingDraft[text]" has a null value in JSON.');
        assert(json.containsKey(r'proposed_solution'), 'Required key "MeetingDraft[proposed_solution]" is missing from JSON.');
        assert(json.containsKey(r'quote'), 'Required key "MeetingDraft[quote]" is missing from JSON.');
        assert(json[r'quote'] != null, 'Required key "MeetingDraft[quote]" has a null value in JSON.');
        assert(json.containsKey(r'author'), 'Required key "MeetingDraft[author]" is missing from JSON.');
        assert(json.containsKey(r'appeal'), 'Required key "MeetingDraft[appeal]" is missing from JSON.');
        return true;
      }());

      return MeetingDraft(
        id: mapValueOfType<int>(json, r'id')!,
        meetingId: mapValueOfType<int>(json, r'meeting_id')!,
        status: MeetingDraftStatus.fromJson(json[r'status'])!,
        type: AppealType.fromJson(json[r'type'])!,
        category: CategoryRef.fromJson(json[r'category']),
        priority: Priority.fromJson(json[r'priority'])!,
        summary: mapValueOfType<String>(json, r'summary')!,
        text: mapValueOfType<String>(json, r'text')!,
        proposedSolution: mapValueOfType<String>(json, r'proposed_solution'),
        quote: mapValueOfType<String>(json, r'quote')!,
        author: UserBrief.fromJson(json[r'author']),
        appeal: AppealRef.fromJson(json[r'appeal']),
      );
    }
    return null;
  }

  static List<MeetingDraft> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MeetingDraft>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeetingDraft.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MeetingDraft> mapFromJson(dynamic json) {
    final map = <String, MeetingDraft>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MeetingDraft.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MeetingDraft-objects as value to a dart map
  static Map<String, List<MeetingDraft>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MeetingDraft>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MeetingDraft.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'meeting_id',
    'status',
    'type',
    'category',
    'priority',
    'summary',
    'text',
    'proposed_solution',
    'quote',
    'author',
    'appeal',
  };
}

