//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VoteRequest {
  /// Returns a new [VoteRequest] instance.
  VoteRequest({
    required this.value,
  });

  VoteValue value;

  @override
  bool operator ==(Object other) => identical(this, other) || other is VoteRequest &&
    other.value == value;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (value.hashCode);

  @override
  String toString() => 'VoteRequest[value=$value]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'value'] = this.value;
    return json;
  }

  /// Returns a new [VoteRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VoteRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'value'), 'Required key "VoteRequest[value]" is missing from JSON.');
        assert(json[r'value'] != null, 'Required key "VoteRequest[value]" has a null value in JSON.');
        return true;
      }());

      return VoteRequest(
        value: VoteValue.fromJson(json[r'value'])!,
      );
    }
    return null;
  }

  static List<VoteRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VoteRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VoteRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VoteRequest> mapFromJson(dynamic json) {
    final map = <String, VoteRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VoteRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VoteRequest-objects as value to a dart map
  static Map<String, List<VoteRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VoteRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VoteRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'value',
  };
}

