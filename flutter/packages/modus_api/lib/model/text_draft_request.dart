//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TextDraftRequest {
  /// Returns a new [TextDraftRequest] instance.
  TextDraftRequest({
    required this.text,
    this.forwardedFrom,
  });

  String text;

  /// Откуда переслано сообщение (название чата или имя), если это пересылка
  String? forwardedFrom;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TextDraftRequest &&
    other.text == text &&
    other.forwardedFrom == forwardedFrom;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (text.hashCode) +
    (forwardedFrom == null ? 0 : forwardedFrom!.hashCode);

  @override
  String toString() => 'TextDraftRequest[text=$text, forwardedFrom=$forwardedFrom]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'text'] = this.text;
    if (this.forwardedFrom != null) {
      json[r'forwarded_from'] = this.forwardedFrom;
    } else {
      json[r'forwarded_from'] = null;
    }
    return json;
  }

  /// Returns a new [TextDraftRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TextDraftRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'text'), 'Required key "TextDraftRequest[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "TextDraftRequest[text]" has a null value in JSON.');
        return true;
      }());

      return TextDraftRequest(
        text: mapValueOfType<String>(json, r'text')!,
        forwardedFrom: mapValueOfType<String>(json, r'forwarded_from'),
      );
    }
    return null;
  }

  static List<TextDraftRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TextDraftRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TextDraftRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TextDraftRequest> mapFromJson(dynamic json) {
    final map = <String, TextDraftRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TextDraftRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TextDraftRequest-objects as value to a dart map
  static Map<String, List<TextDraftRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TextDraftRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TextDraftRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'text',
  };
}

