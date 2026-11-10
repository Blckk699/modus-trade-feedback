//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AppealCreate {
  /// Returns a new [AppealCreate] instance.
  AppealCreate({
    required this.type,
    this.categoryId,
    required this.priority,
    required this.text,
    this.summary,
    this.proposedSolution,
    this.source_ = AppealCreateSource_Enum.form,
    this.forwardedFrom,
  });

  AppealType type;

  /// null — категория не определена, обращение уходит в очередь администратора
  int? categoryId;

  Priority priority;

  String text;

  /// Краткая суть; если пусто — первые слова текста
  String? summary;

  String? proposedSolution;

  AppealCreateSource_Enum source_;

  /// Для пересылки в бот — откуда переслано (из `TextDraftRequest.forwarded_from`)
  String? forwardedFrom;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppealCreate &&
    other.type == type &&
    other.categoryId == categoryId &&
    other.priority == priority &&
    other.text == text &&
    other.summary == summary &&
    other.proposedSolution == proposedSolution &&
    other.source_ == source_ &&
    other.forwardedFrom == forwardedFrom;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (categoryId == null ? 0 : categoryId!.hashCode) +
    (priority.hashCode) +
    (text.hashCode) +
    (summary == null ? 0 : summary!.hashCode) +
    (proposedSolution == null ? 0 : proposedSolution!.hashCode) +
    (source_.hashCode) +
    (forwardedFrom == null ? 0 : forwardedFrom!.hashCode);

  @override
  String toString() => 'AppealCreate[type=$type, categoryId=$categoryId, priority=$priority, text=$text, summary=$summary, proposedSolution=$proposedSolution, source_=$source_, forwardedFrom=$forwardedFrom]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
    if (this.categoryId != null) {
      json[r'category_id'] = this.categoryId;
    } else {
      json[r'category_id'] = null;
    }
      json[r'priority'] = this.priority;
      json[r'text'] = this.text;
    if (this.summary != null) {
      json[r'summary'] = this.summary;
    } else {
      json[r'summary'] = null;
    }
    if (this.proposedSolution != null) {
      json[r'proposed_solution'] = this.proposedSolution;
    } else {
      json[r'proposed_solution'] = null;
    }
      json[r'source'] = this.source_;
    if (this.forwardedFrom != null) {
      json[r'forwarded_from'] = this.forwardedFrom;
    } else {
      json[r'forwarded_from'] = null;
    }
    return json;
  }

  /// Returns a new [AppealCreate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppealCreate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'type'), 'Required key "AppealCreate[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "AppealCreate[type]" has a null value in JSON.');
        assert(json.containsKey(r'priority'), 'Required key "AppealCreate[priority]" is missing from JSON.');
        assert(json[r'priority'] != null, 'Required key "AppealCreate[priority]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "AppealCreate[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "AppealCreate[text]" has a null value in JSON.');
        return true;
      }());

      return AppealCreate(
        type: AppealType.fromJson(json[r'type'])!,
        categoryId: mapValueOfType<int>(json, r'category_id'),
        priority: Priority.fromJson(json[r'priority'])!,
        text: mapValueOfType<String>(json, r'text')!,
        summary: mapValueOfType<String>(json, r'summary'),
        proposedSolution: mapValueOfType<String>(json, r'proposed_solution'),
        source_: AppealCreateSource_Enum.fromJson(json[r'source']) ?? AppealCreateSource_Enum.form,
        forwardedFrom: mapValueOfType<String>(json, r'forwarded_from'),
      );
    }
    return null;
  }

  static List<AppealCreate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealCreate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealCreate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppealCreate> mapFromJson(dynamic json) {
    final map = <String, AppealCreate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppealCreate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppealCreate-objects as value to a dart map
  static Map<String, List<AppealCreate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AppealCreate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppealCreate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'priority',
    'text',
  };
}


enum AppealCreateSource_Enum {
  form._(r'form'),
  bot._(r'bot'),
  ;

  /// Instantiate a new enum with the provided value.
  const AppealCreateSource_Enum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AppealCreateSource_Enum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AppealCreateSource_Enum? fromJson(dynamic value) => AppealCreateSource_EnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AppealCreateSource_Enum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AppealCreateSource_Enum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealCreateSource_Enum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealCreateSource_Enum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AppealCreateSource_Enum] to String,
/// and [decode] dynamic data back to [AppealCreateSource_Enum].
class AppealCreateSource_EnumTypeTransformer {
  factory AppealCreateSource_EnumTypeTransformer() => _instance ??= const AppealCreateSource_EnumTypeTransformer._();

  const AppealCreateSource_EnumTypeTransformer._();

  String encode(AppealCreateSource_Enum data) => data._value;

  /// Returns the instance of [AppealCreateSource_Enum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AppealCreateSource_Enum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AppealCreateSource_Enum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'form': return AppealCreateSource_Enum.form;
        case r'bot': return AppealCreateSource_Enum.bot;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AppealCreateSource_EnumTypeTransformer? _instance;
}


