//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MeetingBrief {
  /// Returns a new [MeetingBrief] instance.
  MeetingBrief({
    required this.id,
    required this.title,
    required this.status,
    required this.draftsTotal,
    required this.draftsPending,
    required this.uploadedBy,
    required this.createdAt,
  });

  int id;

  String title;

  MeetingStatus status;

  int draftsTotal;

  int draftsPending;

  UserBrief uploadedBy;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MeetingBrief &&
    other.id == id &&
    other.title == title &&
    other.status == status &&
    other.draftsTotal == draftsTotal &&
    other.draftsPending == draftsPending &&
    other.uploadedBy == uploadedBy &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (title.hashCode) +
    (status.hashCode) +
    (draftsTotal.hashCode) +
    (draftsPending.hashCode) +
    (uploadedBy.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'MeetingBrief[id=$id, title=$title, status=$status, draftsTotal=$draftsTotal, draftsPending=$draftsPending, uploadedBy=$uploadedBy, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'title'] = this.title;
      json[r'status'] = this.status;
      json[r'drafts_total'] = this.draftsTotal;
      json[r'drafts_pending'] = this.draftsPending;
      json[r'uploaded_by'] = this.uploadedBy;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [MeetingBrief] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MeetingBrief? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "MeetingBrief[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "MeetingBrief[id]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "MeetingBrief[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "MeetingBrief[title]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "MeetingBrief[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "MeetingBrief[status]" has a null value in JSON.');
        assert(json.containsKey(r'drafts_total'), 'Required key "MeetingBrief[drafts_total]" is missing from JSON.');
        assert(json[r'drafts_total'] != null, 'Required key "MeetingBrief[drafts_total]" has a null value in JSON.');
        assert(json.containsKey(r'drafts_pending'), 'Required key "MeetingBrief[drafts_pending]" is missing from JSON.');
        assert(json[r'drafts_pending'] != null, 'Required key "MeetingBrief[drafts_pending]" has a null value in JSON.');
        assert(json.containsKey(r'uploaded_by'), 'Required key "MeetingBrief[uploaded_by]" is missing from JSON.');
        assert(json[r'uploaded_by'] != null, 'Required key "MeetingBrief[uploaded_by]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "MeetingBrief[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "MeetingBrief[created_at]" has a null value in JSON.');
        return true;
      }());

      return MeetingBrief(
        id: mapValueOfType<int>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        status: MeetingStatus.fromJson(json[r'status'])!,
        draftsTotal: mapValueOfType<int>(json, r'drafts_total')!,
        draftsPending: mapValueOfType<int>(json, r'drafts_pending')!,
        uploadedBy: UserBrief.fromJson(json[r'uploaded_by'])!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<MeetingBrief> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MeetingBrief>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeetingBrief.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MeetingBrief> mapFromJson(dynamic json) {
    final map = <String, MeetingBrief>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MeetingBrief.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MeetingBrief-objects as value to a dart map
  static Map<String, List<MeetingBrief>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MeetingBrief>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MeetingBrief.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'title',
    'status',
    'drafts_total',
    'drafts_pending',
    'uploaded_by',
    'created_at',
  };
}

