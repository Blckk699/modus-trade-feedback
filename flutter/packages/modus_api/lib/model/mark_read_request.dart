//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MarkReadRequest {
  /// Returns a new [MarkReadRequest] instance.
  MarkReadRequest({
    this.all,
    this.appealId,
    this.ids = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? all;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? appealId;

  List<int> ids;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MarkReadRequest &&
    other.all == all &&
    other.appealId == appealId &&
    _deepEquality.equals(other.ids, ids);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (all == null ? 0 : all!.hashCode) +
    (appealId == null ? 0 : appealId!.hashCode) +
    (ids.hashCode);

  @override
  String toString() => 'MarkReadRequest[all=$all, appealId=$appealId, ids=$ids]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.all != null) {
      json[r'all'] = this.all;
    } else {
      json[r'all'] = null;
    }
    if (this.appealId != null) {
      json[r'appeal_id'] = this.appealId;
    } else {
      json[r'appeal_id'] = null;
    }
      json[r'ids'] = this.ids;
    return json;
  }

  /// Returns a new [MarkReadRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MarkReadRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return MarkReadRequest(
        all: mapValueOfType<bool>(json, r'all'),
        appealId: mapValueOfType<int>(json, r'appeal_id'),
        ids: json[r'ids'] is Iterable
            ? (json[r'ids'] as Iterable).cast<int>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<MarkReadRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MarkReadRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MarkReadRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MarkReadRequest> mapFromJson(dynamic json) {
    final map = <String, MarkReadRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MarkReadRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MarkReadRequest-objects as value to a dart map
  static Map<String, List<MarkReadRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MarkReadRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MarkReadRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

