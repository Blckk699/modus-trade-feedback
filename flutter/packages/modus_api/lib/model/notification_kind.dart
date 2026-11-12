//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// appeal_assigned — ответственному: новое назначение (в т. ч. переназначение); appeal_created — автору: номер, ответственный, срок; status_changed — автору и участникам; clarification_requested — автору: вопрос; clarification_answered — ответственному: ответ автора; message_received — новое сообщение в переписке; deadline_reminder — ответственному: срок истёк; escalation_head — руководителю: ответственный не ответил; appeal_merged — автору повтора; name_consent_request — автору при выносе на обсуждение; discussion_closed — автору: итог обсуждения; digest — утренняя сводка; access_request_created — администраторам и собственнику: новая заявка на доступ (`path=/settings/access-requests`); access_request_approved — заявителю: доступ открыт, бот показывает меню и вход; access_request_rejected — заявителю: отказ с причиной (у получателя нет `user_id`) 
enum NotificationKind {
  appealAssigned._(r'appeal_assigned'),
  appealCreated._(r'appeal_created'),
  statusChanged._(r'status_changed'),
  clarificationRequested._(r'clarification_requested'),
  clarificationAnswered._(r'clarification_answered'),
  messageReceived._(r'message_received'),
  deadlineReminder._(r'deadline_reminder'),
  escalationHead._(r'escalation_head'),
  appealMerged._(r'appeal_merged'),
  nameConsentRequest._(r'name_consent_request'),
  discussionClosed._(r'discussion_closed'),
  digest._(r'digest'),
  accessRequestCreated._(r'access_request_created'),
  accessRequestApproved._(r'access_request_approved'),
  accessRequestRejected._(r'access_request_rejected'),
  ;

  /// Instantiate a new enum with the provided value.
  const NotificationKind._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NotificationKind] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NotificationKind? fromJson(dynamic value) => NotificationKindTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NotificationKind]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NotificationKind> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationKind>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationKind.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NotificationKind] to String,
/// and [decode] dynamic data back to [NotificationKind].
class NotificationKindTypeTransformer {
  factory NotificationKindTypeTransformer() => _instance ??= const NotificationKindTypeTransformer._();

  const NotificationKindTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(NotificationKind data) => data._value;

  /// Returns the instance of [NotificationKind] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NotificationKind? decode(dynamic data, {bool allowNull = true}) {
    if (data is NotificationKind) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'appeal_assigned': return NotificationKind.appealAssigned;
        case r'appeal_created': return NotificationKind.appealCreated;
        case r'status_changed': return NotificationKind.statusChanged;
        case r'clarification_requested': return NotificationKind.clarificationRequested;
        case r'clarification_answered': return NotificationKind.clarificationAnswered;
        case r'message_received': return NotificationKind.messageReceived;
        case r'deadline_reminder': return NotificationKind.deadlineReminder;
        case r'escalation_head': return NotificationKind.escalationHead;
        case r'appeal_merged': return NotificationKind.appealMerged;
        case r'name_consent_request': return NotificationKind.nameConsentRequest;
        case r'discussion_closed': return NotificationKind.discussionClosed;
        case r'digest': return NotificationKind.digest;
        case r'access_request_created': return NotificationKind.accessRequestCreated;
        case r'access_request_approved': return NotificationKind.accessRequestApproved;
        case r'access_request_rejected': return NotificationKind.accessRequestRejected;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NotificationKindTypeTransformer? _instance;
}

