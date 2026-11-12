//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HistoryEvent {
  /// Returns a new [HistoryEvent] instance.
  HistoryEvent({
    required this.id,
    required this.appealId,
    required this.kind,
    required this.actor,
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.comment,
    required this.createdAt,
  });

  int id;

  int appealId;

  HistoryEventKindEnum kind;

  /// null — система
  UserBrief? actor;

  String? field;

  String? oldValue;

  String? newValue;

  /// Причина переназначения, текст решения и т. п. У первого назначения без причины — null
  String? comment;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HistoryEvent &&
    other.id == id &&
    other.appealId == appealId &&
    other.kind == kind &&
    other.actor == actor &&
    other.field == field &&
    other.oldValue == oldValue &&
    other.newValue == newValue &&
    other.comment == comment &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (appealId.hashCode) +
    (kind.hashCode) +
    (actor == null ? 0 : actor!.hashCode) +
    (field == null ? 0 : field!.hashCode) +
    (oldValue == null ? 0 : oldValue!.hashCode) +
    (newValue == null ? 0 : newValue!.hashCode) +
    (comment == null ? 0 : comment!.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'HistoryEvent[id=$id, appealId=$appealId, kind=$kind, actor=$actor, field=$field, oldValue=$oldValue, newValue=$newValue, comment=$comment, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'appeal_id'] = this.appealId;
      json[r'kind'] = this.kind;
    if (this.actor != null) {
      json[r'actor'] = this.actor;
    } else {
      json[r'actor'] = null;
    }
    if (this.field != null) {
      json[r'field'] = this.field;
    } else {
      json[r'field'] = null;
    }
    if (this.oldValue != null) {
      json[r'old_value'] = this.oldValue;
    } else {
      json[r'old_value'] = null;
    }
    if (this.newValue != null) {
      json[r'new_value'] = this.newValue;
    } else {
      json[r'new_value'] = null;
    }
    if (this.comment != null) {
      json[r'comment'] = this.comment;
    } else {
      json[r'comment'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [HistoryEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HistoryEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "HistoryEvent[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "HistoryEvent[id]" has a null value in JSON.');
        assert(json.containsKey(r'appeal_id'), 'Required key "HistoryEvent[appeal_id]" is missing from JSON.');
        assert(json[r'appeal_id'] != null, 'Required key "HistoryEvent[appeal_id]" has a null value in JSON.');
        assert(json.containsKey(r'kind'), 'Required key "HistoryEvent[kind]" is missing from JSON.');
        assert(json[r'kind'] != null, 'Required key "HistoryEvent[kind]" has a null value in JSON.');
        assert(json.containsKey(r'actor'), 'Required key "HistoryEvent[actor]" is missing from JSON.');
        assert(json.containsKey(r'field'), 'Required key "HistoryEvent[field]" is missing from JSON.');
        assert(json.containsKey(r'old_value'), 'Required key "HistoryEvent[old_value]" is missing from JSON.');
        assert(json.containsKey(r'new_value'), 'Required key "HistoryEvent[new_value]" is missing from JSON.');
        assert(json.containsKey(r'comment'), 'Required key "HistoryEvent[comment]" is missing from JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "HistoryEvent[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "HistoryEvent[created_at]" has a null value in JSON.');
        return true;
      }());

      return HistoryEvent(
        id: mapValueOfType<int>(json, r'id')!,
        appealId: mapValueOfType<int>(json, r'appeal_id')!,
        kind: HistoryEventKindEnum.fromJson(json[r'kind'])!,
        actor: UserBrief.fromJson(json[r'actor']),
        field: mapValueOfType<String>(json, r'field'),
        oldValue: mapValueOfType<String>(json, r'old_value'),
        newValue: mapValueOfType<String>(json, r'new_value'),
        comment: mapValueOfType<String>(json, r'comment'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<HistoryEvent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HistoryEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HistoryEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HistoryEvent> mapFromJson(dynamic json) {
    final map = <String, HistoryEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HistoryEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HistoryEvent-objects as value to a dart map
  static Map<String, List<HistoryEvent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HistoryEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HistoryEvent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'appeal_id',
    'kind',
    'actor',
    'field',
    'old_value',
    'new_value',
    'comment',
    'created_at',
  };
}


enum HistoryEventKindEnum {
  created._(r'created'),
  assigned._(r'assigned'),
  reassigned._(r'reassigned'),
  statusChanged._(r'status_changed'),
  deadlineSet._(r'deadline_set'),
  clarificationRequested._(r'clarification_requested'),
  clarificationAnswered._(r'clarification_answered'),
  escalated._(r'escalated'),
  merged._(r'merged'),
  participantAdded._(r'participant_added'),
  attachmentAdded._(r'attachment_added'),
  discussionPublished._(r'discussion_published'),
  discussionClosed._(r'discussion_closed'),
  bitrixTaskCreated._(r'bitrix_task_created'),
  fieldChanged._(r'field_changed'),
  ;

  /// Instantiate a new enum with the provided value.
  const HistoryEventKindEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [HistoryEventKindEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static HistoryEventKindEnum? fromJson(dynamic value) => HistoryEventKindEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [HistoryEventKindEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<HistoryEventKindEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HistoryEventKindEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HistoryEventKindEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [HistoryEventKindEnum] to String,
/// and [decode] dynamic data back to [HistoryEventKindEnum].
class HistoryEventKindEnumTypeTransformer {
  factory HistoryEventKindEnumTypeTransformer() => _instance ??= const HistoryEventKindEnumTypeTransformer._();

  const HistoryEventKindEnumTypeTransformer._();

  String encode(HistoryEventKindEnum data) => data._value;

  /// Returns the instance of [HistoryEventKindEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  HistoryEventKindEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is HistoryEventKindEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'created': return HistoryEventKindEnum.created;
        case r'assigned': return HistoryEventKindEnum.assigned;
        case r'reassigned': return HistoryEventKindEnum.reassigned;
        case r'status_changed': return HistoryEventKindEnum.statusChanged;
        case r'deadline_set': return HistoryEventKindEnum.deadlineSet;
        case r'clarification_requested': return HistoryEventKindEnum.clarificationRequested;
        case r'clarification_answered': return HistoryEventKindEnum.clarificationAnswered;
        case r'escalated': return HistoryEventKindEnum.escalated;
        case r'merged': return HistoryEventKindEnum.merged;
        case r'participant_added': return HistoryEventKindEnum.participantAdded;
        case r'attachment_added': return HistoryEventKindEnum.attachmentAdded;
        case r'discussion_published': return HistoryEventKindEnum.discussionPublished;
        case r'discussion_closed': return HistoryEventKindEnum.discussionClosed;
        case r'bitrix_task_created': return HistoryEventKindEnum.bitrixTaskCreated;
        case r'field_changed': return HistoryEventKindEnum.fieldChanged;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static HistoryEventKindEnumTypeTransformer? _instance;
}


