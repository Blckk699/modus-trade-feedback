//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// `unauthorized` 401 · `invalid_telegram_auth` 401 · `invalid_login_code` 401 · `user_not_registered` 403 · `user_disabled` 403 · `dev_login_disabled` 403 · `forbidden` 403 · `not_found` 404 · `conflict` 409 · `invalid_transition` 409 · `merge_not_allowed` 409 · `voting_closed` 409 · `file_too_large` 413 · `validation_error` 422 · `audio_empty` 422 · `audio_too_long` 422 · `bitrix_unavailable` 502 · `ai_unavailable` 503 · `internal_error` 500 
enum ErrorCode {
  unauthorized._(r'unauthorized'),
  invalidTelegramAuth._(r'invalid_telegram_auth'),
  invalidLoginCode._(r'invalid_login_code'),
  userNotRegistered._(r'user_not_registered'),
  userDisabled._(r'user_disabled'),
  devLoginDisabled._(r'dev_login_disabled'),
  forbidden._(r'forbidden'),
  notFound._(r'not_found'),
  conflict._(r'conflict'),
  invalidTransition._(r'invalid_transition'),
  mergeNotAllowed._(r'merge_not_allowed'),
  votingClosed._(r'voting_closed'),
  fileTooLarge._(r'file_too_large'),
  validationError._(r'validation_error'),
  audioEmpty._(r'audio_empty'),
  audioTooLong._(r'audio_too_long'),
  bitrixUnavailable._(r'bitrix_unavailable'),
  aiUnavailable._(r'ai_unavailable'),
  internalError._(r'internal_error'),
  ;

  /// Instantiate a new enum with the provided value.
  const ErrorCode._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ErrorCode] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ErrorCode? fromJson(dynamic value) => ErrorCodeTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ErrorCode]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ErrorCode> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ErrorCode>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ErrorCode.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ErrorCode] to String,
/// and [decode] dynamic data back to [ErrorCode].
class ErrorCodeTypeTransformer {
  factory ErrorCodeTypeTransformer() => _instance ??= const ErrorCodeTypeTransformer._();

  const ErrorCodeTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ErrorCode data) => data._value;

  /// Returns the instance of [ErrorCode] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ErrorCode? decode(dynamic data, {bool allowNull = true}) {
    if (data is ErrorCode) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'unauthorized': return ErrorCode.unauthorized;
        case r'invalid_telegram_auth': return ErrorCode.invalidTelegramAuth;
        case r'invalid_login_code': return ErrorCode.invalidLoginCode;
        case r'user_not_registered': return ErrorCode.userNotRegistered;
        case r'user_disabled': return ErrorCode.userDisabled;
        case r'dev_login_disabled': return ErrorCode.devLoginDisabled;
        case r'forbidden': return ErrorCode.forbidden;
        case r'not_found': return ErrorCode.notFound;
        case r'conflict': return ErrorCode.conflict;
        case r'invalid_transition': return ErrorCode.invalidTransition;
        case r'merge_not_allowed': return ErrorCode.mergeNotAllowed;
        case r'voting_closed': return ErrorCode.votingClosed;
        case r'file_too_large': return ErrorCode.fileTooLarge;
        case r'validation_error': return ErrorCode.validationError;
        case r'audio_empty': return ErrorCode.audioEmpty;
        case r'audio_too_long': return ErrorCode.audioTooLong;
        case r'bitrix_unavailable': return ErrorCode.bitrixUnavailable;
        case r'ai_unavailable': return ErrorCode.aiUnavailable;
        case r'internal_error': return ErrorCode.internalError;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ErrorCodeTypeTransformer? _instance;
}

