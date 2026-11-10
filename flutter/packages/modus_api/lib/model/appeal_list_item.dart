//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AppealListItem {
  /// Returns a new [AppealListItem] instance.
  AppealListItem({
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
  AppealListItemAccessEnum access;

  bool hasUnread;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppealListItem &&
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
    other.updatedAt == updatedAt;

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
    (updatedAt.hashCode);

  @override
  String toString() => 'AppealListItem[id=$id, number=$number, type=$type, category=$category, department=$department, priority=$priority, status=$status, summary=$summary, author=$author, assignee=$assignee, source_=$source_, firstResponseDueAt=$firstResponseDueAt, dueState=$dueState, escalationLevel=$escalationLevel, participantsCount=$participantsCount, mergedInto=$mergedInto, access=$access, hasUnread=$hasUnread, createdAt=$createdAt, updatedAt=$updatedAt]';

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
    return json;
  }

  /// Returns a new [AppealListItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppealListItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "AppealListItem[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "AppealListItem[id]" has a null value in JSON.');
        assert(json.containsKey(r'number'), 'Required key "AppealListItem[number]" is missing from JSON.');
        assert(json[r'number'] != null, 'Required key "AppealListItem[number]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "AppealListItem[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "AppealListItem[type]" has a null value in JSON.');
        assert(json.containsKey(r'category'), 'Required key "AppealListItem[category]" is missing from JSON.');
        assert(json.containsKey(r'department'), 'Required key "AppealListItem[department]" is missing from JSON.');
        assert(json.containsKey(r'priority'), 'Required key "AppealListItem[priority]" is missing from JSON.');
        assert(json[r'priority'] != null, 'Required key "AppealListItem[priority]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "AppealListItem[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "AppealListItem[status]" has a null value in JSON.');
        assert(json.containsKey(r'summary'), 'Required key "AppealListItem[summary]" is missing from JSON.');
        assert(json.containsKey(r'author'), 'Required key "AppealListItem[author]" is missing from JSON.');
        assert(json.containsKey(r'assignee'), 'Required key "AppealListItem[assignee]" is missing from JSON.');
        assert(json.containsKey(r'source'), 'Required key "AppealListItem[source]" is missing from JSON.');
        assert(json[r'source'] != null, 'Required key "AppealListItem[source]" has a null value in JSON.');
        assert(json.containsKey(r'first_response_due_at'), 'Required key "AppealListItem[first_response_due_at]" is missing from JSON.');
        assert(json.containsKey(r'due_state'), 'Required key "AppealListItem[due_state]" is missing from JSON.');
        assert(json[r'due_state'] != null, 'Required key "AppealListItem[due_state]" has a null value in JSON.');
        assert(json.containsKey(r'escalation_level'), 'Required key "AppealListItem[escalation_level]" is missing from JSON.');
        assert(json[r'escalation_level'] != null, 'Required key "AppealListItem[escalation_level]" has a null value in JSON.');
        assert(json.containsKey(r'participants_count'), 'Required key "AppealListItem[participants_count]" is missing from JSON.');
        assert(json[r'participants_count'] != null, 'Required key "AppealListItem[participants_count]" has a null value in JSON.');
        assert(json.containsKey(r'merged_into'), 'Required key "AppealListItem[merged_into]" is missing from JSON.');
        assert(json.containsKey(r'access'), 'Required key "AppealListItem[access]" is missing from JSON.');
        assert(json[r'access'] != null, 'Required key "AppealListItem[access]" has a null value in JSON.');
        assert(json.containsKey(r'has_unread'), 'Required key "AppealListItem[has_unread]" is missing from JSON.');
        assert(json[r'has_unread'] != null, 'Required key "AppealListItem[has_unread]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "AppealListItem[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "AppealListItem[created_at]" has a null value in JSON.');
        assert(json.containsKey(r'updated_at'), 'Required key "AppealListItem[updated_at]" is missing from JSON.');
        assert(json[r'updated_at'] != null, 'Required key "AppealListItem[updated_at]" has a null value in JSON.');
        return true;
      }());

      return AppealListItem(
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
        access: AppealListItemAccessEnum.fromJson(json[r'access'])!,
        hasUnread: mapValueOfType<bool>(json, r'has_unread')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        updatedAt: mapDateTime(json, r'updated_at', r'')!,
      );
    }
    return null;
  }

  static List<AppealListItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealListItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealListItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppealListItem> mapFromJson(dynamic json) {
    final map = <String, AppealListItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppealListItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppealListItem-objects as value to a dart map
  static Map<String, List<AppealListItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AppealListItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppealListItem.listFromJson(entry.value, growable: growable,);
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
  };
}

/// participant — пользователь видит основное обращение только как участник склеенного повтора
enum AppealListItemAccessEnum {
  full._(r'full'),
  participant._(r'participant'),
  ;

  /// Instantiate a new enum with the provided value.
  const AppealListItemAccessEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AppealListItemAccessEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AppealListItemAccessEnum? fromJson(dynamic value) => AppealListItemAccessEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AppealListItemAccessEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AppealListItemAccessEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealListItemAccessEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealListItemAccessEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AppealListItemAccessEnum] to String,
/// and [decode] dynamic data back to [AppealListItemAccessEnum].
class AppealListItemAccessEnumTypeTransformer {
  factory AppealListItemAccessEnumTypeTransformer() => _instance ??= const AppealListItemAccessEnumTypeTransformer._();

  const AppealListItemAccessEnumTypeTransformer._();

  String encode(AppealListItemAccessEnum data) => data._value;

  /// Returns the instance of [AppealListItemAccessEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AppealListItemAccessEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AppealListItemAccessEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'full': return AppealListItemAccessEnum.full;
        case r'participant': return AppealListItemAccessEnum.participant;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AppealListItemAccessEnumTypeTransformer? _instance;
}


