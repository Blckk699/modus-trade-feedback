//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


enum AppealAction {
  take._(r'take'),
  requestInfo._(r'request_info'),
  replyClarification._(r'reply_clarification'),
  startWork._(r'start_work'),
  reject._(r'reject'),
  implement._(r'implement'),
  acceptFeedback._(r'accept_feedback'),
  merge._(r'merge'),
  reassign._(r'reassign'),
  publishDiscussion._(r'publish_discussion'),
  createBitrixTask._(r'create_bitrix_task'),
  sendMessage._(r'send_message'),
  uploadAttachment._(r'upload_attachment'),
  ;

  /// Instantiate a new enum with the provided value.
  const AppealAction._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AppealAction] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AppealAction? fromJson(dynamic value) => AppealActionTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AppealAction]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AppealAction> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealAction>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealAction.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AppealAction] to String,
/// and [decode] dynamic data back to [AppealAction].
class AppealActionTypeTransformer {
  factory AppealActionTypeTransformer() => _instance ??= const AppealActionTypeTransformer._();

  const AppealActionTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(AppealAction data) => data._value;

  /// Returns the instance of [AppealAction] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AppealAction? decode(dynamic data, {bool allowNull = true}) {
    if (data is AppealAction) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'take': return AppealAction.take;
        case r'request_info': return AppealAction.requestInfo;
        case r'reply_clarification': return AppealAction.replyClarification;
        case r'start_work': return AppealAction.startWork;
        case r'reject': return AppealAction.reject;
        case r'implement': return AppealAction.implement;
        case r'accept_feedback': return AppealAction.acceptFeedback;
        case r'merge': return AppealAction.merge;
        case r'reassign': return AppealAction.reassign;
        case r'publish_discussion': return AppealAction.publishDiscussion;
        case r'create_bitrix_task': return AppealAction.createBitrixTask;
        case r'send_message': return AppealAction.sendMessage;
        case r'upload_attachment': return AppealAction.uploadAttachment;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AppealActionTypeTransformer? _instance;
}

