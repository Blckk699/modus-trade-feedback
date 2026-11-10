//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AppealDraft {
  /// Returns a new [AppealDraft] instance.
  AppealDraft({
    required this.type,
    required this.category,
    required this.priority,
    required this.summary,
    required this.text,
    required this.proposedSolution,
    required this.transcript,
  });

  AppealType type;

  CategoryRef? category;

  Priority priority;

  String summary;

  /// Текст обращения (для голоса — расшифровка)
  String text;

  String? proposedSolution;

  /// Расшифровка голосового; null для текста
  String? transcript;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppealDraft &&
    other.type == type &&
    other.category == category &&
    other.priority == priority &&
    other.summary == summary &&
    other.text == text &&
    other.proposedSolution == proposedSolution &&
    other.transcript == transcript;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (priority.hashCode) +
    (summary.hashCode) +
    (text.hashCode) +
    (proposedSolution == null ? 0 : proposedSolution!.hashCode) +
    (transcript == null ? 0 : transcript!.hashCode);

  @override
  String toString() => 'AppealDraft[type=$type, category=$category, priority=$priority, summary=$summary, text=$text, proposedSolution=$proposedSolution, transcript=$transcript]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
      json[r'priority'] = this.priority;
      json[r'summary'] = this.summary;
      json[r'text'] = this.text;
    if (this.proposedSolution != null) {
      json[r'proposed_solution'] = this.proposedSolution;
    } else {
      json[r'proposed_solution'] = null;
    }
    if (this.transcript != null) {
      json[r'transcript'] = this.transcript;
    } else {
      json[r'transcript'] = null;
    }
    return json;
  }

  /// Returns a new [AppealDraft] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppealDraft? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'type'), 'Required key "AppealDraft[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "AppealDraft[type]" has a null value in JSON.');
        assert(json.containsKey(r'category'), 'Required key "AppealDraft[category]" is missing from JSON.');
        assert(json.containsKey(r'priority'), 'Required key "AppealDraft[priority]" is missing from JSON.');
        assert(json[r'priority'] != null, 'Required key "AppealDraft[priority]" has a null value in JSON.');
        assert(json.containsKey(r'summary'), 'Required key "AppealDraft[summary]" is missing from JSON.');
        assert(json[r'summary'] != null, 'Required key "AppealDraft[summary]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "AppealDraft[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "AppealDraft[text]" has a null value in JSON.');
        assert(json.containsKey(r'proposed_solution'), 'Required key "AppealDraft[proposed_solution]" is missing from JSON.');
        assert(json.containsKey(r'transcript'), 'Required key "AppealDraft[transcript]" is missing from JSON.');
        return true;
      }());

      return AppealDraft(
        type: AppealType.fromJson(json[r'type'])!,
        category: CategoryRef.fromJson(json[r'category']),
        priority: Priority.fromJson(json[r'priority'])!,
        summary: mapValueOfType<String>(json, r'summary')!,
        text: mapValueOfType<String>(json, r'text')!,
        proposedSolution: mapValueOfType<String>(json, r'proposed_solution'),
        transcript: mapValueOfType<String>(json, r'transcript'),
      );
    }
    return null;
  }

  static List<AppealDraft> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealDraft>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealDraft.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppealDraft> mapFromJson(dynamic json) {
    final map = <String, AppealDraft>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppealDraft.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppealDraft-objects as value to a dart map
  static Map<String, List<AppealDraft>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AppealDraft>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppealDraft.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'category',
    'priority',
    'summary',
    'text',
    'proposed_solution',
    'transcript',
  };
}

