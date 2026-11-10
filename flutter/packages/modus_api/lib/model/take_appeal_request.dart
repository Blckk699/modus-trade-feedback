//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TakeAppealRequest {
  /// Returns a new [TakeAppealRequest] instance.
  TakeAppealRequest({
    this.comment,
  });

  /// Необязательный первый ответ автору, попадает в переписку
  String? comment;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TakeAppealRequest &&
    other.comment == comment;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (comment == null ? 0 : comment!.hashCode);

  @override
  String toString() => 'TakeAppealRequest[comment=$comment]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.comment != null) {
      json[r'comment'] = this.comment;
    } else {
      json[r'comment'] = null;
    }
    return json;
  }

  /// Returns a new [TakeAppealRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TakeAppealRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TakeAppealRequest(
        comment: mapValueOfType<String>(json, r'comment'),
      );
    }
    return null;
  }

  static List<TakeAppealRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TakeAppealRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TakeAppealRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TakeAppealRequest> mapFromJson(dynamic json) {
    final map = <String, TakeAppealRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TakeAppealRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TakeAppealRequest-objects as value to a dart map
  static Map<String, List<TakeAppealRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TakeAppealRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TakeAppealRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

