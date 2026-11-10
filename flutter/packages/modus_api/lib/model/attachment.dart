//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Attachment {
  /// Returns a new [Attachment] instance.
  Attachment({
    required this.id,
    required this.appealId,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.uploadedBy,
    required this.createdAt,
  });

  int id;

  int appealId;

  String filename;

  String contentType;

  int sizeBytes;

  /// Путь от корня сервера (`/api/v1/attachments/{id}`), требует авторизации
  String downloadUrl;

  UserBrief uploadedBy;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Attachment &&
    other.id == id &&
    other.appealId == appealId &&
    other.filename == filename &&
    other.contentType == contentType &&
    other.sizeBytes == sizeBytes &&
    other.downloadUrl == downloadUrl &&
    other.uploadedBy == uploadedBy &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (appealId.hashCode) +
    (filename.hashCode) +
    (contentType.hashCode) +
    (sizeBytes.hashCode) +
    (downloadUrl.hashCode) +
    (uploadedBy.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'Attachment[id=$id, appealId=$appealId, filename=$filename, contentType=$contentType, sizeBytes=$sizeBytes, downloadUrl=$downloadUrl, uploadedBy=$uploadedBy, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'appeal_id'] = this.appealId;
      json[r'filename'] = this.filename;
      json[r'content_type'] = this.contentType;
      json[r'size_bytes'] = this.sizeBytes;
      json[r'download_url'] = this.downloadUrl;
      json[r'uploaded_by'] = this.uploadedBy;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [Attachment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Attachment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Attachment[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Attachment[id]" has a null value in JSON.');
        assert(json.containsKey(r'appeal_id'), 'Required key "Attachment[appeal_id]" is missing from JSON.');
        assert(json[r'appeal_id'] != null, 'Required key "Attachment[appeal_id]" has a null value in JSON.');
        assert(json.containsKey(r'filename'), 'Required key "Attachment[filename]" is missing from JSON.');
        assert(json[r'filename'] != null, 'Required key "Attachment[filename]" has a null value in JSON.');
        assert(json.containsKey(r'content_type'), 'Required key "Attachment[content_type]" is missing from JSON.');
        assert(json[r'content_type'] != null, 'Required key "Attachment[content_type]" has a null value in JSON.');
        assert(json.containsKey(r'size_bytes'), 'Required key "Attachment[size_bytes]" is missing from JSON.');
        assert(json[r'size_bytes'] != null, 'Required key "Attachment[size_bytes]" has a null value in JSON.');
        assert(json.containsKey(r'download_url'), 'Required key "Attachment[download_url]" is missing from JSON.');
        assert(json[r'download_url'] != null, 'Required key "Attachment[download_url]" has a null value in JSON.');
        assert(json.containsKey(r'uploaded_by'), 'Required key "Attachment[uploaded_by]" is missing from JSON.');
        assert(json[r'uploaded_by'] != null, 'Required key "Attachment[uploaded_by]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "Attachment[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "Attachment[created_at]" has a null value in JSON.');
        return true;
      }());

      return Attachment(
        id: mapValueOfType<int>(json, r'id')!,
        appealId: mapValueOfType<int>(json, r'appeal_id')!,
        filename: mapValueOfType<String>(json, r'filename')!,
        contentType: mapValueOfType<String>(json, r'content_type')!,
        sizeBytes: mapValueOfType<int>(json, r'size_bytes')!,
        downloadUrl: mapValueOfType<String>(json, r'download_url')!,
        uploadedBy: UserBrief.fromJson(json[r'uploaded_by'])!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<Attachment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Attachment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Attachment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Attachment> mapFromJson(dynamic json) {
    final map = <String, Attachment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Attachment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Attachment-objects as value to a dart map
  static Map<String, List<Attachment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Attachment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Attachment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'appeal_id',
    'filename',
    'content_type',
    'size_bytes',
    'download_url',
    'uploaded_by',
    'created_at',
  };
}

