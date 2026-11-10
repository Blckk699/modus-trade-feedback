//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Appeal {
  /// Returns a new [Appeal] instance.
  Appeal({
    required this.id,
    required this.number,
    required this.type,
    required this.category,
    required this.department,
    required this.priority,
    required this.status,
    required this.summary,
    required this.author,
    required this.assignee,
    required this.source_,
    required this.firstResponseDueAt,
    required this.dueState,
    required this.escalationLevel,
    required this.participantsCount,
    required this.mergedInto,
    required this.access,
    required this.hasUnread,
    required this.createdAt,
    required this.updatedAt,
    required this.text,
    required this.proposedSolution,
    required this.firstResponseAt,
    required this.decision,
    required this.rejectionReason,
    required this.result,
    required this.publicSummary,
    required this.publicResult,
    required this.forwardedFrom,
    required this.closedReason,
    required this.bitrixTask,
    required this.discussion,
    this.attachments = const [],
    this.viewerRelations = const [],
    this.allowedActions = const [],
  });

  int id;

  String number;

  AppealType type;

  CategoryRef? category;

  /// Подразделение категории — по нему руководитель видит обращение
  DepartmentRef? department;

  Priority priority;

  AppealStatus status;

  String? summary;

  /// null для участника склеенного повтора (чужое имя скрыто)
  UserBrief? author;

  /// null — в очереди нераспределённых
  UserBrief? assignee;

  AppealSource source_;

  /// Срок первого ответа — единственный срок в системе. null у отзывов и нераспределённых.
  DateTime? firstResponseDueAt;

  DueState dueState;

  /// 0 — нет; 1 — напомнили ответственному; 2 — уведомили руководителя; 3 — «Зависло» в сводке собственника
  ///
  /// Minimum value: 0
  /// Maximum value: 3
  int escalationLevel;

  /// Сколько человек сообщили о проблеме (автор + авторы присоединённых повторов)
  int participantsCount;

  /// Для повтора — основное обращение (его статус показывается автору повтора)
  AppealRef? mergedInto;

  /// participant — пользователь видит основное обращение только как участник склеенного повтора
  AppealAccessEnum access;

  bool hasUnread;

  DateTime createdAt;

  DateTime updatedAt;

  /// null при access=participant
  String? text;

  String? proposedSolution;

  DateTime? firstResponseAt;

  /// Принятое решение при переводе в работу
  String? decision;

  String? rejectionReason;

  /// Зафиксированный результат («Реализовано»)
  String? result;

  /// Что предложили — публичная формулировка для ленты реализованного
  String? publicSummary;

  /// Что сделали — публичная формулировка результата для ленты
  String? publicResult;

  /// Откуда переслано сообщение, если обращение подано пересылкой в бот
  String? forwardedFrom;

  ClosedReason? closedReason;

  Object? bitrixTask;

  Object? discussion;

  List<Attachment> attachments;

  /// Почему пользователь видит обращение
  List<ViewerRelation> viewerRelations;

  /// Действия, доступные пользователю сейчас. Клиент показывает только их.
  List<AppealAction> allowedActions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Appeal &&
    other.id == id &&
    other.number == number &&
    other.type == type &&
    other.category == category &&
    other.department == department &&
    other.priority == priority &&
    other.status == status &&
    other.summary == summary &&
    other.author == author &&
    other.assignee == assignee &&
    other.source_ == source_ &&
    other.firstResponseDueAt == firstResponseDueAt &&
    other.dueState == dueState &&
    other.escalationLevel == escalationLevel &&
    other.participantsCount == participantsCount &&
    other.mergedInto == mergedInto &&
    other.access == access &&
    other.hasUnread == hasUnread &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.text == text &&
    other.proposedSolution == proposedSolution &&
    other.firstResponseAt == firstResponseAt &&
    other.decision == decision &&
    other.rejectionReason == rejectionReason &&
    other.result == result &&
    other.publicSummary == publicSummary &&
    other.publicResult == publicResult &&
    other.forwardedFrom == forwardedFrom &&
    other.closedReason == closedReason &&
    other.bitrixTask == bitrixTask &&
    other.discussion == discussion &&
    _deepEquality.equals(other.attachments, attachments) &&
    _deepEquality.equals(other.viewerRelations, viewerRelations) &&
    _deepEquality.equals(other.allowedActions, allowedActions);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (number.hashCode) +
    (type.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (priority.hashCode) +
    (status.hashCode) +
    (summary == null ? 0 : summary!.hashCode) +
    (author == null ? 0 : author!.hashCode) +
    (assignee == null ? 0 : assignee!.hashCode) +
    (source_.hashCode) +
    (firstResponseDueAt == null ? 0 : firstResponseDueAt!.hashCode) +
    (dueState.hashCode) +
    (escalationLevel.hashCode) +
    (participantsCount.hashCode) +
    (mergedInto == null ? 0 : mergedInto!.hashCode) +
    (access.hashCode) +
    (hasUnread.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode) +
    (text == null ? 0 : text!.hashCode) +
    (proposedSolution == null ? 0 : proposedSolution!.hashCode) +
    (firstResponseAt == null ? 0 : firstResponseAt!.hashCode) +
    (decision == null ? 0 : decision!.hashCode) +
    (rejectionReason == null ? 0 : rejectionReason!.hashCode) +
    (result == null ? 0 : result!.hashCode) +
    (publicSummary == null ? 0 : publicSummary!.hashCode) +
    (publicResult == null ? 0 : publicResult!.hashCode) +
    (forwardedFrom == null ? 0 : forwardedFrom!.hashCode) +
    (closedReason == null ? 0 : closedReason!.hashCode) +
    (bitrixTask == null ? 0 : bitrixTask!.hashCode) +
    (discussion == null ? 0 : discussion!.hashCode) +
    (attachments.hashCode) +
    (viewerRelations.hashCode) +
    (allowedActions.hashCode);

  @override
  String toString() => 'Appeal[id=$id, number=$number, type=$type, category=$category, department=$department, priority=$priority, status=$status, summary=$summary, author=$author, assignee=$assignee, source_=$source_, firstResponseDueAt=$firstResponseDueAt, dueState=$dueState, escalationLevel=$escalationLevel, participantsCount=$participantsCount, mergedInto=$mergedInto, access=$access, hasUnread=$hasUnread, createdAt=$createdAt, updatedAt=$updatedAt, text=$text, proposedSolution=$proposedSolution, firstResponseAt=$firstResponseAt, decision=$decision, rejectionReason=$rejectionReason, result=$result, publicSummary=$publicSummary, publicResult=$publicResult, forwardedFrom=$forwardedFrom, closedReason=$closedReason, bitrixTask=$bitrixTask, discussion=$discussion, attachments=$attachments, viewerRelations=$viewerRelations, allowedActions=$allowedActions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'number'] = this.number;
      json[r'type'] = this.type;
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
      json[r'priority'] = this.priority;
      json[r'status'] = this.status;
    if (this.summary != null) {
      json[r'summary'] = this.summary;
    } else {
      json[r'summary'] = null;
    }
    if (this.author != null) {
      json[r'author'] = this.author;
    } else {
      json[r'author'] = null;
    }
    if (this.assignee != null) {
      json[r'assignee'] = this.assignee;
    } else {
      json[r'assignee'] = null;
    }
      json[r'source'] = this.source_;
    if (this.firstResponseDueAt != null) {
      json[r'first_response_due_at'] = this.firstResponseDueAt!.toUtc().toIso8601String();
    } else {
      json[r'first_response_due_at'] = null;
    }
      json[r'due_state'] = this.dueState;
      json[r'escalation_level'] = this.escalationLevel;
      json[r'participants_count'] = this.participantsCount;
    if (this.mergedInto != null) {
      json[r'merged_into'] = this.mergedInto;
    } else {
      json[r'merged_into'] = null;
    }
      json[r'access'] = this.access;
      json[r'has_unread'] = this.hasUnread;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'updated_at'] = this.updatedAt.toUtc().toIso8601String();
    if (this.text != null) {
      json[r'text'] = this.text;
    } else {
      json[r'text'] = null;
    }
    if (this.proposedSolution != null) {
      json[r'proposed_solution'] = this.proposedSolution;
    } else {
      json[r'proposed_solution'] = null;
    }
    if (this.firstResponseAt != null) {
      json[r'first_response_at'] = this.firstResponseAt!.toUtc().toIso8601String();
    } else {
      json[r'first_response_at'] = null;
    }
    if (this.decision != null) {
      json[r'decision'] = this.decision;
    } else {
      json[r'decision'] = null;
    }
    if (this.rejectionReason != null) {
      json[r'rejection_reason'] = this.rejectionReason;
    } else {
      json[r'rejection_reason'] = null;
    }
    if (this.result != null) {
      json[r'result'] = this.result;
    } else {
      json[r'result'] = null;
    }
    if (this.publicSummary != null) {
      json[r'public_summary'] = this.publicSummary;
    } else {
      json[r'public_summary'] = null;
    }
    if (this.publicResult != null) {
      json[r'public_result'] = this.publicResult;
    } else {
      json[r'public_result'] = null;
    }
    if (this.forwardedFrom != null) {
      json[r'forwarded_from'] = this.forwardedFrom;
    } else {
      json[r'forwarded_from'] = null;
    }
    if (this.closedReason != null) {
      json[r'closed_reason'] = this.closedReason;
    } else {
      json[r'closed_reason'] = null;
    }
    if (this.bitrixTask != null) {
      json[r'bitrix_task'] = this.bitrixTask;
    } else {
      json[r'bitrix_task'] = null;
    }
    if (this.discussion != null) {
      json[r'discussion'] = this.discussion;
    } else {
      json[r'discussion'] = null;
    }
      json[r'attachments'] = this.attachments;
      json[r'viewer_relations'] = this.viewerRelations;
      json[r'allowed_actions'] = this.allowedActions;
    return json;
  }

  /// Returns a new [Appeal] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Appeal? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Appeal[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Appeal[id]" has a null value in JSON.');
        assert(json.containsKey(r'number'), 'Required key "Appeal[number]" is missing from JSON.');
        assert(json[r'number'] != null, 'Required key "Appeal[number]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "Appeal[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "Appeal[type]" has a null value in JSON.');
        assert(json.containsKey(r'category'), 'Required key "Appeal[category]" is missing from JSON.');
        assert(json.containsKey(r'department'), 'Required key "Appeal[department]" is missing from JSON.');
        assert(json.containsKey(r'priority'), 'Required key "Appeal[priority]" is missing from JSON.');
        assert(json[r'priority'] != null, 'Required key "Appeal[priority]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "Appeal[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Appeal[status]" has a null value in JSON.');
        assert(json.containsKey(r'summary'), 'Required key "Appeal[summary]" is missing from JSON.');
        assert(json.containsKey(r'author'), 'Required key "Appeal[author]" is missing from JSON.');
        assert(json.containsKey(r'assignee'), 'Required key "Appeal[assignee]" is missing from JSON.');
        assert(json.containsKey(r'source'), 'Required key "Appeal[source]" is missing from JSON.');
        assert(json[r'source'] != null, 'Required key "Appeal[source]" has a null value in JSON.');
        assert(json.containsKey(r'first_response_due_at'), 'Required key "Appeal[first_response_due_at]" is missing from JSON.');
        assert(json.containsKey(r'due_state'), 'Required key "Appeal[due_state]" is missing from JSON.');
        assert(json[r'due_state'] != null, 'Required key "Appeal[due_state]" has a null value in JSON.');
        assert(json.containsKey(r'escalation_level'), 'Required key "Appeal[escalation_level]" is missing from JSON.');
        assert(json[r'escalation_level'] != null, 'Required key "Appeal[escalation_level]" has a null value in JSON.');
        assert(json.containsKey(r'participants_count'), 'Required key "Appeal[participants_count]" is missing from JSON.');
        assert(json[r'participants_count'] != null, 'Required key "Appeal[participants_count]" has a null value in JSON.');
        assert(json.containsKey(r'merged_into'), 'Required key "Appeal[merged_into]" is missing from JSON.');
        assert(json.containsKey(r'access'), 'Required key "Appeal[access]" is missing from JSON.');
        assert(json[r'access'] != null, 'Required key "Appeal[access]" has a null value in JSON.');
        assert(json.containsKey(r'has_unread'), 'Required key "Appeal[has_unread]" is missing from JSON.');
        assert(json[r'has_unread'] != null, 'Required key "Appeal[has_unread]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "Appeal[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "Appeal[created_at]" has a null value in JSON.');
        assert(json.containsKey(r'updated_at'), 'Required key "Appeal[updated_at]" is missing from JSON.');
        assert(json[r'updated_at'] != null, 'Required key "Appeal[updated_at]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "Appeal[text]" is missing from JSON.');
        assert(json.containsKey(r'proposed_solution'), 'Required key "Appeal[proposed_solution]" is missing from JSON.');
        assert(json.containsKey(r'first_response_at'), 'Required key "Appeal[first_response_at]" is missing from JSON.');
        assert(json.containsKey(r'decision'), 'Required key "Appeal[decision]" is missing from JSON.');
        assert(json.containsKey(r'rejection_reason'), 'Required key "Appeal[rejection_reason]" is missing from JSON.');
        assert(json.containsKey(r'result'), 'Required key "Appeal[result]" is missing from JSON.');
        assert(json.containsKey(r'public_summary'), 'Required key "Appeal[public_summary]" is missing from JSON.');
        assert(json.containsKey(r'public_result'), 'Required key "Appeal[public_result]" is missing from JSON.');
        assert(json.containsKey(r'forwarded_from'), 'Required key "Appeal[forwarded_from]" is missing from JSON.');
        assert(json.containsKey(r'closed_reason'), 'Required key "Appeal[closed_reason]" is missing from JSON.');
        assert(json.containsKey(r'bitrix_task'), 'Required key "Appeal[bitrix_task]" is missing from JSON.');
        assert(json.containsKey(r'discussion'), 'Required key "Appeal[discussion]" is missing from JSON.');
        assert(json.containsKey(r'attachments'), 'Required key "Appeal[attachments]" is missing from JSON.');
        assert(json[r'attachments'] != null, 'Required key "Appeal[attachments]" has a null value in JSON.');
        assert(json.containsKey(r'viewer_relations'), 'Required key "Appeal[viewer_relations]" is missing from JSON.');
        assert(json[r'viewer_relations'] != null, 'Required key "Appeal[viewer_relations]" has a null value in JSON.');
        assert(json.containsKey(r'allowed_actions'), 'Required key "Appeal[allowed_actions]" is missing from JSON.');
        assert(json[r'allowed_actions'] != null, 'Required key "Appeal[allowed_actions]" has a null value in JSON.');
        return true;
      }());

      return Appeal(
        id: mapValueOfType<int>(json, r'id')!,
        number: mapValueOfType<String>(json, r'number')!,
        type: AppealType.fromJson(json[r'type'])!,
        category: CategoryRef.fromJson(json[r'category']),
        department: DepartmentRef.fromJson(json[r'department']),
        priority: Priority.fromJson(json[r'priority'])!,
        status: AppealStatus.fromJson(json[r'status'])!,
        summary: mapValueOfType<String>(json, r'summary'),
        author: UserBrief.fromJson(json[r'author']),
        assignee: UserBrief.fromJson(json[r'assignee']),
        source_: AppealSource.fromJson(json[r'source'])!,
        firstResponseDueAt: mapDateTime(json, r'first_response_due_at', r''),
        dueState: DueState.fromJson(json[r'due_state'])!,
        escalationLevel: mapValueOfType<int>(json, r'escalation_level')!,
        participantsCount: mapValueOfType<int>(json, r'participants_count')!,
        mergedInto: AppealRef.fromJson(json[r'merged_into']),
        access: AppealAccessEnum.fromJson(json[r'access'])!,
        hasUnread: mapValueOfType<bool>(json, r'has_unread')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        updatedAt: mapDateTime(json, r'updated_at', r'')!,
        text: mapValueOfType<String>(json, r'text'),
        proposedSolution: mapValueOfType<String>(json, r'proposed_solution'),
        firstResponseAt: mapDateTime(json, r'first_response_at', r''),
        decision: mapValueOfType<String>(json, r'decision'),
        rejectionReason: mapValueOfType<String>(json, r'rejection_reason'),
        result: mapValueOfType<String>(json, r'result'),
        publicSummary: mapValueOfType<String>(json, r'public_summary'),
        publicResult: mapValueOfType<String>(json, r'public_result'),
        forwardedFrom: mapValueOfType<String>(json, r'forwarded_from'),
        closedReason: ClosedReason.fromJson(json[r'closed_reason']),
        bitrixTask: mapValueOfType<Object>(json, r'bitrix_task'),
        discussion: mapValueOfType<Object>(json, r'discussion'),
        attachments: Attachment.listFromJson(json[r'attachments']),
        viewerRelations: ViewerRelation.listFromJson(json[r'viewer_relations']),
        allowedActions: AppealAction.listFromJson(json[r'allowed_actions']),
      );
    }
    return null;
  }

  static List<Appeal> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Appeal>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Appeal.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Appeal> mapFromJson(dynamic json) {
    final map = <String, Appeal>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Appeal.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Appeal-objects as value to a dart map
  static Map<String, List<Appeal>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Appeal>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Appeal.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'number',
    'type',
    'category',
    'department',
    'priority',
    'status',
    'summary',
    'author',
    'assignee',
    'source',
    'first_response_due_at',
    'due_state',
    'escalation_level',
    'participants_count',
    'merged_into',
    'access',
    'has_unread',
    'created_at',
    'updated_at',
    'text',
    'proposed_solution',
    'first_response_at',
    'decision',
    'rejection_reason',
    'result',
    'public_summary',
    'public_result',
    'forwarded_from',
    'closed_reason',
    'bitrix_task',
    'discussion',
    'attachments',
    'viewer_relations',
    'allowed_actions',
  };
}

/// participant — пользователь видит основное обращение только как участник склеенного повтора
enum AppealAccessEnum {
  full._(r'full'),
  participant._(r'participant'),
  ;

  /// Instantiate a new enum with the provided value.
  const AppealAccessEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AppealAccessEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AppealAccessEnum? fromJson(dynamic value) => AppealAccessEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AppealAccessEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AppealAccessEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealAccessEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealAccessEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AppealAccessEnum] to String,
/// and [decode] dynamic data back to [AppealAccessEnum].
class AppealAccessEnumTypeTransformer {
  factory AppealAccessEnumTypeTransformer() => _instance ??= const AppealAccessEnumTypeTransformer._();

  const AppealAccessEnumTypeTransformer._();

  String encode(AppealAccessEnum data) => data._value;

  /// Returns the instance of [AppealAccessEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AppealAccessEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AppealAccessEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'full': return AppealAccessEnum.full;
        case r'participant': return AppealAccessEnum.participant;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AppealAccessEnumTypeTransformer? _instance;
}


