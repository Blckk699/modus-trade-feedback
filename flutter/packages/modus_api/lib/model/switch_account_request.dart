//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SwitchAccountRequest {
  /// Returns a new [SwitchAccountRequest] instance.
  SwitchAccountRequest({
    required this.userId,
  });

  /// `id` из `Me.switch_targets`
  int userId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SwitchAccountRequest &&
    other.userId == userId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId.hashCode);

  @override
  String toString() => 'SwitchAccountRequest[userId=$userId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user_id'] = this.userId;
    return json;
  }

  /// Returns a new [SwitchAccountRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SwitchAccountRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'user_id'), 'Required key "SwitchAccountRequest[user_id]" is missing from JSON.');
        assert(json[r'user_id'] != null, 'Required key "SwitchAccountRequest[user_id]" has a null value in JSON.');
        return true;
      }());

      return SwitchAccountRequest(
        userId: mapValueOfType<int>(json, r'user_id')!,
      );
    }
    return null;
  }

  static List<SwitchAccountRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SwitchAccountRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SwitchAccountRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SwitchAccountRequest> mapFromJson(dynamic json) {
    final map = <String, SwitchAccountRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SwitchAccountRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SwitchAccountRequest-objects as value to a dart map
  static Map<String, List<SwitchAccountRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SwitchAccountRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SwitchAccountRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user_id',
  };
}

