//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


enum NotificationButtonType {
  openAppeal._(r'open_appeal'),
  openAnalytics._(r'open_analytics'),
  openDiscussion._(r'open_discussion'),
  replyClarification._(r'reply_clarification'),
  nameConsentShow._(r'name_consent_show'),
  nameConsentHide._(r'name_consent_hide'),
  ;

  /// Instantiate a new enum with the provided value.
  const NotificationButtonType._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NotificationButtonType] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NotificationButtonType? fromJson(dynamic value) => NotificationButtonTypeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NotificationButtonType]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NotificationButtonType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationButtonType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationButtonType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationButtonType] to String,
/// and [decode] dynamic data back to [NotificationButtonType].
class NotificationButtonTypeTypeTransformer {
  factory NotificationButtonTypeTypeTransformer() => _instance ??= const NotificationButtonTypeTypeTransformer._();

  const NotificationButtonTypeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(NotificationButtonType data) => data._value;

  /// Returns the instance of [NotificationButtonType] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationButtonType? decode(dynamic data, {bool allowNull = true}) {
    if (data is NotificationButtonType) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'open_appeal': return NotificationButtonType.openAppeal;
        case r'open_analytics': return NotificationButtonType.openAnalytics;
        case r'open_discussion': return NotificationButtonType.openDiscussion;
        case r'reply_clarification': return NotificationButtonType.replyClarification;
        case r'name_consent_show': return NotificationButtonType.nameConsentShow;
        case r'name_consent_hide': return NotificationButtonType.nameConsentHide;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NotificationButtonTypeTypeTransformer? _instance;
}

