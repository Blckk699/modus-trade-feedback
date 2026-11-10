//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Meeting {
  /// Returns a new [Meeting] instance.
  Meeting({
    required this.id,
    required this.title,
    required this.status,
    required this.error,
    required this.transcript,
    required this.uploadedBy,
    this.drafts = const [],
    required this.createdAt,
  });

  int id;

  String title;

  MeetingStatus status;

  /// Текст ошибки для пользователя при status=failed
  String? error;

  String? transcript;

  UserBrief uploadedBy;

  List<MeetingDraft> drafts;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Meeting &&
    other.id == id &&
    other.title == title &&
    other.status == status &&
    other.error == error &&
    other.transcript == transcript &&
    other.uploadedBy == uploadedBy &&
    _deepEquality.equals(other.drafts, drafts) &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (title.hashCode) +
    (status.hashCode) +
    (error == null ? 0 : error!.hashCode) +
    (transcript == null ? 0 : transcript!.hashCode) +
    (uploadedBy.hashCode) +
    (drafts.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Meeting[id=$id, title=$title, status=$status, error=$error, transcript=$transcript, uploadedBy=$uploadedBy, drafts=$drafts, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'title'] = this.title;
      json[r'status'] = this.status;
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
    if (this.transcript != null) {
      json[r'transcript'] = this.transcript;
    } else {
      json[r'transcript'] = null;
    }
      json[r'uploaded_by'] = this.uploadedBy;
      json[r'drafts'] = this.drafts;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Meeting] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Meeting? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Meeting[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Meeting[id]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "Meeting[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "Meeting[title]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "Meeting[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Meeting[status]" has a null value in JSON.');
        assert(json.containsKey(r'error'), 'Required key "Meeting[error]" is missing from JSON.');
        assert(json.containsKey(r'transcript'), 'Required key "Meeting[transcript]" is missing from JSON.');
        assert(json.containsKey(r'uploaded_by'), 'Required key "Meeting[uploaded_by]" is missing from JSON.');
        assert(json[r'uploaded_by'] != null, 'Required key "Meeting[uploaded_by]" has a null value in JSON.');
        assert(json.containsKey(r'drafts'), 'Required key "Meeting[drafts]" is missing from JSON.');
        assert(json[r'drafts'] != null, 'Required key "Meeting[drafts]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "Meeting[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "Meeting[created_at]" has a null value in JSON.');
        return true;
      }());

      return Meeting(
        id: mapValueOfType<int>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        status: MeetingStatus.fromJson(json[r'status'])!,
        error: mapValueOfType<String>(json, r'error'),
        transcript: mapValueOfType<String>(json, r'transcript'),
        uploadedBy: UserBrief.fromJson(json[r'uploaded_by'])!,
        drafts: MeetingDraft.listFromJson(json[r'drafts']),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<Meeting> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Meeting>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Meeting.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Meeting> mapFromJson(dynamic json) {
    final map = <String, Meeting>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Meeting.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Meeting-objects as value to a dart map
  static Map<String, List<Meeting>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Meeting>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Meeting.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'title',
    'status',
    'error',
    'transcript',
    'uploaded_by',
    'drafts',
    'created_at',
  };
}

