//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


enum AppealSource {
  bot._(r'bot'),
  form._(r'form'),
  meeting._(r'meeting'),
  ;

  /// Instantiate a new enum with the provided value.
  const AppealSource._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AppealSource] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AppealSource? fromJson(dynamic value) => AppealSourceTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AppealSource]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AppealSource> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealSource>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealSource.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AppealSource] to String,
/// and [decode] dynamic data back to [AppealSource].
class AppealSourceTypeTransformer {
  factory AppealSourceTypeTransformer() => _instance ??= const AppealSourceTypeTransformer._();

  const AppealSourceTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(AppealSource data) => data._value;

  /// Returns the instance of [AppealSource] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AppealSource? decode(dynamic data, {bool allowNull = true}) {
    if (data is AppealSource) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'bot': return AppealSource.bot;
        case r'form': return AppealSource.form;
        case r'meeting': return AppealSource.meeting;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AppealSourceTypeTransformer? _instance;
}

