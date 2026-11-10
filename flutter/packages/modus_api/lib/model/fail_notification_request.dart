//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FailNotificationRequest {
  /// Returns a new [FailNotificationRequest] instance.
  FailNotificationRequest({
    this.error,
    this.permanent = false,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? error;

  bool permanent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FailNotificationRequest &&
    other.error == error &&
    other.permanent == permanent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (error == null ? 0 : error!.hashCode) +
    (permanent.hashCode);

  @override
  String toString() => 'FailNotificationRequest[error=$error, permanent=$permanent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
      json[r'permanent'] = this.permanent;
    return json;
  }

  /// Returns a new [FailNotificationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FailNotificationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return FailNotificationRequest(
        error: mapValueOfType<String>(json, r'error'),
        permanent: mapValueOfType<bool>(json, r'permanent') ?? false,
      );
    }
    return null;
  }

  static List<FailNotificationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FailNotificationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FailNotificationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FailNotificationRequest> mapFromJson(dynamic json) {
    final map = <String, FailNotificationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FailNotificationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FailNotificationRequest-objects as value to a dart map
  static Map<String, List<FailNotificationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FailNotificationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FailNotificationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

