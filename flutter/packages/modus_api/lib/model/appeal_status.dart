//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// new — Новое, in_review — На рассмотрении, awaiting_info — Ожидает уточнения, in_progress — В работе, implemented — Реализовано, rejected — Отклонено, closed — Закрыто 
enum AppealStatus {
  new_._(r'new'),
  inReview._(r'in_review'),
  awaitingInfo._(r'awaiting_info'),
  inProgress._(r'in_progress'),
  implemented._(r'implemented'),
  rejected._(r'rejected'),
  closed._(r'closed'),
  ;

  /// Instantiate a new enum with the provided value.
  const AppealStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AppealStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AppealStatus? fromJson(dynamic value) => AppealStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AppealStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AppealStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AppealStatus] to String,
/// and [decode] dynamic data back to [AppealStatus].
class AppealStatusTypeTransformer {
  factory AppealStatusTypeTransformer() => _instance ??= const AppealStatusTypeTransformer._();

  const AppealStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(AppealStatus data) => data._value;

  /// Returns the instance of [AppealStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AppealStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is AppealStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'new': return AppealStatus.new_;
        case r'in_review': return AppealStatus.inReview;
        case r'awaiting_info': return AppealStatus.awaitingInfo;
        case r'in_progress': return AppealStatus.inProgress;
        case r'implemented': return AppealStatus.implemented;
        case r'rejected': return AppealStatus.rejected;
        case r'closed': return AppealStatus.closed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AppealStatusTypeTransformer? _instance;
}

