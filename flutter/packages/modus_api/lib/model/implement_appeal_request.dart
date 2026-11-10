//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ImplementAppealRequest {
  /// Returns a new [ImplementAppealRequest] instance.
  ImplementAppealRequest({
    required this.result,
    this.publicSummary,
    this.publicResult,
  });

  String result;

  /// Что предложили — для ленты
  String? publicSummary;

  /// Что сделали — публичная формулировка для ленты
  String? publicResult;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ImplementAppealRequest &&
    other.result == result &&
    other.publicSummary == publicSummary &&
    other.publicResult == publicResult;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (result.hashCode) +
    (publicSummary == null ? 0 : publicSummary!.hashCode) +
    (publicResult == null ? 0 : publicResult!.hashCode);

  @override
  String toString() => 'ImplementAppealRequest[result=$result, publicSummary=$publicSummary, publicResult=$publicResult]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'result'] = this.result;
    if (this.publicSummary != null) {
      json[r'public_summary'] = this.publicSummary;
    } else {
      json[r'public_summary'] = null;
    }
    if (this.publicResult != null) {
      json[r'public_result'] = this.publicResult;
    } else {
      json[r'public_result'] = null;
    }
    return json;
  }

  /// Returns a new [ImplementAppealRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ImplementAppealRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'result'), 'Required key "ImplementAppealRequest[result]" is missing from JSON.');
        assert(json[r'result'] != null, 'Required key "ImplementAppealRequest[result]" has a null value in JSON.');
        return true;
      }());

      return ImplementAppealRequest(
        result: mapValueOfType<String>(json, r'result')!,
        publicSummary: mapValueOfType<String>(json, r'public_summary'),
        publicResult: mapValueOfType<String>(json, r'public_result'),
      );
    }
    return null;
  }

  static List<ImplementAppealRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ImplementAppealRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ImplementAppealRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ImplementAppealRequest> mapFromJson(dynamic json) {
    final map = <String, ImplementAppealRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ImplementAppealRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ImplementAppealRequest-objects as value to a dart map
  static Map<String, List<ImplementAppealRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ImplementAppealRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ImplementAppealRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'result',
  };
}

