//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Discussion {
  /// Returns a new [Discussion] instance.
  Discussion({
    required this.id,
    required this.appeal,
    required this.publicText,
    required this.deadline,
    required this.status,
    required this.authorNameConsent,
    required this.authorDisplay,
    required this.department,
    required this.votesFor,
    required this.votesAgainst,
    required this.myVote,
    required this.commentsCount,
    required this.outcome,
    required this.createdBy,
    required this.createdAt,
    required this.closedAt,
    required this.canVote,
    required this.canClose,
    required this.canSetNameConsent,
  });

  int id;

  DiscussionAppeal appeal;

  String publicText;

  DateTime deadline;

  DiscussionStatus status;

  NameConsent authorNameConsent;

  /// Имя автора при согласии, иначе «Отдел «…»»
  String authorDisplay;

  DepartmentRef? department;

  int votesFor;

  int votesAgainst;

  VoteValue? myVote;

  int commentsCount;

  String? outcome;

  UserBrief createdBy;

  DateTime createdAt;

  DateTime? closedAt;

  bool canVote;

  bool canClose;

  /// true только автору обращения
  bool canSetNameConsent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Discussion &&
    other.id == id &&
    other.appeal == appeal &&
    other.publicText == publicText &&
    other.deadline == deadline &&
    other.status == status &&
    other.authorNameConsent == authorNameConsent &&
    other.authorDisplay == authorDisplay &&
    other.department == department &&
    other.votesFor == votesFor &&
    other.votesAgainst == votesAgainst &&
    other.myVote == myVote &&
    other.commentsCount == commentsCount &&
    other.outcome == outcome &&
    other.createdBy == createdBy &&
    other.createdAt == createdAt &&
    other.closedAt == closedAt &&
    other.canVote == canVote &&
    other.canClose == canClose &&
    other.canSetNameConsent == canSetNameConsent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (appeal.hashCode) +
    (publicText.hashCode) +
    (deadline.hashCode) +
    (status.hashCode) +
    (authorNameConsent.hashCode) +
    (authorDisplay.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (votesFor.hashCode) +
    (votesAgainst.hashCode) +
    (myVote == null ? 0 : myVote!.hashCode) +
    (commentsCount.hashCode) +
    (outcome == null ? 0 : outcome!.hashCode) +
    (createdBy.hashCode) +
    (createdAt.hashCode) +
    (closedAt == null ? 0 : closedAt!.hashCode) +
    (canVote.hashCode) +
    (canClose.hashCode) +
    (canSetNameConsent.hashCode);

  @override
  String toString() => 'Discussion[id=$id, appeal=$appeal, publicText=$publicText, deadline=$deadline, status=$status, authorNameConsent=$authorNameConsent, authorDisplay=$authorDisplay, department=$department, votesFor=$votesFor, votesAgainst=$votesAgainst, myVote=$myVote, commentsCount=$commentsCount, outcome=$outcome, createdBy=$createdBy, createdAt=$createdAt, closedAt=$closedAt, canVote=$canVote, canClose=$canClose, canSetNameConsent=$canSetNameConsent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'appeal'] = this.appeal;
      json[r'public_text'] = this.publicText;
      json[r'deadline'] = this.deadline.toUtc().toIso8601String();
      json[r'status'] = this.status;
      json[r'author_name_consent'] = this.authorNameConsent;
      json[r'author_display'] = this.authorDisplay;
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
      json[r'votes_for'] = this.votesFor;
      json[r'votes_against'] = this.votesAgainst;
    if (this.myVote != null) {
      json[r'my_vote'] = this.myVote;
    } else {
      json[r'my_vote'] = null;
    }
      json[r'comments_count'] = this.commentsCount;
    if (this.outcome != null) {
      json[r'outcome'] = this.outcome;
    } else {
      json[r'outcome'] = null;
    }
      json[r'created_by'] = this.createdBy;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    if (this.closedAt != null) {
      json[r'closed_at'] = this.closedAt!.toUtc().toIso8601String();
    } else {
      json[r'closed_at'] = null;
    }
      json[r'can_vote'] = this.canVote;
      json[r'can_close'] = this.canClose;
      json[r'can_set_name_consent'] = this.canSetNameConsent;
    return json;
  }

  /// Returns a new [Discussion] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Discussion? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Discussion[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Discussion[id]" has a null value in JSON.');
        assert(json.containsKey(r'appeal'), 'Required key "Discussion[appeal]" is missing from JSON.');
        assert(json[r'appeal'] != null, 'Required key "Discussion[appeal]" has a null value in JSON.');
        assert(json.containsKey(r'public_text'), 'Required key "Discussion[public_text]" is missing from JSON.');
        assert(json[r'public_text'] != null, 'Required key "Discussion[public_text]" has a null value in JSON.');
        assert(json.containsKey(r'deadline'), 'Required key "Discussion[deadline]" is missing from JSON.');
        assert(json[r'deadline'] != null, 'Required key "Discussion[deadline]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "Discussion[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Discussion[status]" has a null value in JSON.');
        assert(json.containsKey(r'author_name_consent'), 'Required key "Discussion[author_name_consent]" is missing from JSON.');
        assert(json[r'author_name_consent'] != null, 'Required key "Discussion[author_name_consent]" has a null value in JSON.');
        assert(json.containsKey(r'author_display'), 'Required key "Discussion[author_display]" is missing from JSON.');
        assert(json[r'author_display'] != null, 'Required key "Discussion[author_display]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "Discussion[department]" is missing from JSON.');
        assert(json.containsKey(r'votes_for'), 'Required key "Discussion[votes_for]" is missing from JSON.');
        assert(json[r'votes_for'] != null, 'Required key "Discussion[votes_for]" has a null value in JSON.');
        assert(json.containsKey(r'votes_against'), 'Required key "Discussion[votes_against]" is missing from JSON.');
        assert(json[r'votes_against'] != null, 'Required key "Discussion[votes_against]" has a null value in JSON.');
        assert(json.containsKey(r'my_vote'), 'Required key "Discussion[my_vote]" is missing from JSON.');
        assert(json.containsKey(r'comments_count'), 'Required key "Discussion[comments_count]" is missing from JSON.');
        assert(json[r'comments_count'] != null, 'Required key "Discussion[comments_count]" has a null value in JSON.');
        assert(json.containsKey(r'outcome'), 'Required key "Discussion[outcome]" is missing from JSON.');
        assert(json.containsKey(r'created_by'), 'Required key "Discussion[created_by]" is missing from JSON.');
        assert(json[r'created_by'] != null, 'Required key "Discussion[created_by]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "Discussion[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "Discussion[created_at]" has a null value in JSON.');
        assert(json.containsKey(r'closed_at'), 'Required key "Discussion[closed_at]" is missing from JSON.');
        assert(json.containsKey(r'can_vote'), 'Required key "Discussion[can_vote]" is missing from JSON.');
        assert(json[r'can_vote'] != null, 'Required key "Discussion[can_vote]" has a null value in JSON.');
        assert(json.containsKey(r'can_close'), 'Required key "Discussion[can_close]" is missing from JSON.');
        assert(json[r'can_close'] != null, 'Required key "Discussion[can_close]" has a null value in JSON.');
        assert(json.containsKey(r'can_set_name_consent'), 'Required key "Discussion[can_set_name_consent]" is missing from JSON.');
        assert(json[r'can_set_name_consent'] != null, 'Required key "Discussion[can_set_name_consent]" has a null value in JSON.');
        return true;
      }());

      return Discussion(
        id: mapValueOfType<int>(json, r'id')!,
        appeal: DiscussionAppeal.fromJson(json[r'appeal'])!,
        publicText: mapValueOfType<String>(json, r'public_text')!,
        deadline: mapDateTime(json, r'deadline', r'')!,
        status: DiscussionStatus.fromJson(json[r'status'])!,
        authorNameConsent: NameConsent.fromJson(json[r'author_name_consent'])!,
        authorDisplay: mapValueOfType<String>(json, r'author_display')!,
        department: DepartmentRef.fromJson(json[r'department']),
        votesFor: mapValueOfType<int>(json, r'votes_for')!,
        votesAgainst: mapValueOfType<int>(json, r'votes_against')!,
        myVote: VoteValue.fromJson(json[r'my_vote']),
        commentsCount: mapValueOfType<int>(json, r'comments_count')!,
        outcome: mapValueOfType<String>(json, r'outcome'),
        createdBy: UserBrief.fromJson(json[r'created_by'])!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        closedAt: mapDateTime(json, r'closed_at', r''),
        canVote: mapValueOfType<bool>(json, r'can_vote')!,
        canClose: mapValueOfType<bool>(json, r'can_close')!,
        canSetNameConsent: mapValueOfType<bool>(json, r'can_set_name_consent')!,
      );
    }
    return null;
  }

  static List<Discussion> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Discussion>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Discussion.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Discussion> mapFromJson(dynamic json) {
    final map = <String, Discussion>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Discussion.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Discussion-objects as value to a dart map
  static Map<String, List<Discussion>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Discussion>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Discussion.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'appeal',
    'public_text',
    'deadline',
    'status',
    'author_name_consent',
    'author_display',
    'department',
    'votes_for',
    'votes_against',
    'my_vote',
    'comments_count',
    'outcome',
    'created_by',
    'created_at',
    'closed_at',
    'can_vote',
    'can_close',
    'can_set_name_consent',
  };
}

