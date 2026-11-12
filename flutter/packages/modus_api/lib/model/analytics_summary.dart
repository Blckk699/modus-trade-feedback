//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AnalyticsSummary {
  /// Returns a new [AnalyticsSummary] instance.
  AnalyticsSummary({
    required this.scope,
    required this.department,
    required this.generatedAt,
    required this.total,
    required this.closedCount,
    required this.closedShare,
    required this.avgFirstResponseHours,
    this.byType = const [],
    this.byCategory = const [],
    this.byStatus = const [],
    this.newLast24h = const [],
    this.stuck = const [],
    this.closedLastWeek = const [],
    this.repeatedTopics = const [],
    this.overdue = const [],
    this.assigneeLoad = const [],
    required this.unassignedCount,
  });

  AnalyticsSummaryScopeEnum scope;

  DepartmentRef? department;

  DateTime generatedAt;

  int total;

  /// В финальных статусах (implemented, rejected, closed)
  int closedCount;

  /// Minimum value: 0
  /// Maximum value: 1
  double closedShare;

  /// Среднее время от создания до первого ответа, часы; null — нет данных
  double? avgFirstResponseHours;

  List<CountByType> byType;

  List<CountByCategory> byCategory;

  List<CountByStatus> byStatus;

  List<AppealRef> newLast24h;

  /// Зависшие — шаг эскалации 3
  List<StuckAppeal> stuck;

  List<AppealRef> closedLastWeek;

  List<RepeatedTopic> repeatedTopics;

  /// Все с просроченным сроком первого ответа
  List<StuckAppeal> overdue;

  /// Нагрузка по ответственным в выборке (история 53), по убыванию открытых
  List<AssigneeLoad> assigneeLoad;

  /// Открытых обращений без ответственного в выборке
  int unassignedCount;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AnalyticsSummary &&
    other.scope == scope &&
    other.department == department &&
    other.generatedAt == generatedAt &&
    other.total == total &&
    other.closedCount == closedCount &&
    other.closedShare == closedShare &&
    other.avgFirstResponseHours == avgFirstResponseHours &&
    _deepEquality.equals(other.byType, byType) &&
    _deepEquality.equals(other.byCategory, byCategory) &&
    _deepEquality.equals(other.byStatus, byStatus) &&
    _deepEquality.equals(other.newLast24h, newLast24h) &&
    _deepEquality.equals(other.stuck, stuck) &&
    _deepEquality.equals(other.closedLastWeek, closedLastWeek) &&
    _deepEquality.equals(other.repeatedTopics, repeatedTopics) &&
    _deepEquality.equals(other.overdue, overdue) &&
    _deepEquality.equals(other.assigneeLoad, assigneeLoad) &&
    other.unassignedCount == unassignedCount;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (scope.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (generatedAt.hashCode) +
    (total.hashCode) +
    (closedCount.hashCode) +
    (closedShare.hashCode) +
    (avgFirstResponseHours == null ? 0 : avgFirstResponseHours!.hashCode) +
    (byType.hashCode) +
    (byCategory.hashCode) +
    (byStatus.hashCode) +
    (newLast24h.hashCode) +
    (stuck.hashCode) +
    (closedLastWeek.hashCode) +
    (repeatedTopics.hashCode) +
    (overdue.hashCode) +
    (assigneeLoad.hashCode) +
    (unassignedCount.hashCode);

  @override
  String toString() => 'AnalyticsSummary[scope=$scope, department=$department, generatedAt=$generatedAt, total=$total, closedCount=$closedCount, closedShare=$closedShare, avgFirstResponseHours=$avgFirstResponseHours, byType=$byType, byCategory=$byCategory, byStatus=$byStatus, newLast24h=$newLast24h, stuck=$stuck, closedLastWeek=$closedLastWeek, repeatedTopics=$repeatedTopics, overdue=$overdue, assigneeLoad=$assigneeLoad, unassignedCount=$unassignedCount]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'scope'] = this.scope;
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
      json[r'generated_at'] = this.generatedAt.toUtc().toIso8601String();
      json[r'total'] = this.total;
      json[r'closed_count'] = this.closedCount;
      json[r'closed_share'] = this.closedShare;
    if (this.avgFirstResponseHours != null) {
      json[r'avg_first_response_hours'] = this.avgFirstResponseHours;
    } else {
      json[r'avg_first_response_hours'] = null;
    }
      json[r'by_type'] = this.byType;
      json[r'by_category'] = this.byCategory;
      json[r'by_status'] = this.byStatus;
      json[r'new_last_24h'] = this.newLast24h;
      json[r'stuck'] = this.stuck;
      json[r'closed_last_week'] = this.closedLastWeek;
      json[r'repeated_topics'] = this.repeatedTopics;
      json[r'overdue'] = this.overdue;
      json[r'assignee_load'] = this.assigneeLoad;
      json[r'unassigned_count'] = this.unassignedCount;
    return json;
  }

  /// Returns a new [AnalyticsSummary] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AnalyticsSummary? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'scope'), 'Required key "AnalyticsSummary[scope]" is missing from JSON.');
        assert(json[r'scope'] != null, 'Required key "AnalyticsSummary[scope]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "AnalyticsSummary[department]" is missing from JSON.');
        assert(json.containsKey(r'generated_at'), 'Required key "AnalyticsSummary[generated_at]" is missing from JSON.');
        assert(json[r'generated_at'] != null, 'Required key "AnalyticsSummary[generated_at]" has a null value in JSON.');
        assert(json.containsKey(r'total'), 'Required key "AnalyticsSummary[total]" is missing from JSON.');
        assert(json[r'total'] != null, 'Required key "AnalyticsSummary[total]" has a null value in JSON.');
        assert(json.containsKey(r'closed_count'), 'Required key "AnalyticsSummary[closed_count]" is missing from JSON.');
        assert(json[r'closed_count'] != null, 'Required key "AnalyticsSummary[closed_count]" has a null value in JSON.');
        assert(json.containsKey(r'closed_share'), 'Required key "AnalyticsSummary[closed_share]" is missing from JSON.');
        assert(json[r'closed_share'] != null, 'Required key "AnalyticsSummary[closed_share]" has a null value in JSON.');
        assert(json.containsKey(r'avg_first_response_hours'), 'Required key "AnalyticsSummary[avg_first_response_hours]" is missing from JSON.');
        assert(json.containsKey(r'by_type'), 'Required key "AnalyticsSummary[by_type]" is missing from JSON.');
        assert(json[r'by_type'] != null, 'Required key "AnalyticsSummary[by_type]" has a null value in JSON.');
        assert(json.containsKey(r'by_category'), 'Required key "AnalyticsSummary[by_category]" is missing from JSON.');
        assert(json[r'by_category'] != null, 'Required key "AnalyticsSummary[by_category]" has a null value in JSON.');
        assert(json.containsKey(r'by_status'), 'Required key "AnalyticsSummary[by_status]" is missing from JSON.');
        assert(json[r'by_status'] != null, 'Required key "AnalyticsSummary[by_status]" has a null value in JSON.');
        assert(json.containsKey(r'new_last_24h'), 'Required key "AnalyticsSummary[new_last_24h]" is missing from JSON.');
        assert(json[r'new_last_24h'] != null, 'Required key "AnalyticsSummary[new_last_24h]" has a null value in JSON.');
        assert(json.containsKey(r'stuck'), 'Required key "AnalyticsSummary[stuck]" is missing from JSON.');
        assert(json[r'stuck'] != null, 'Required key "AnalyticsSummary[stuck]" has a null value in JSON.');
        assert(json.containsKey(r'closed_last_week'), 'Required key "AnalyticsSummary[closed_last_week]" is missing from JSON.');
        assert(json[r'closed_last_week'] != null, 'Required key "AnalyticsSummary[closed_last_week]" has a null value in JSON.');
        assert(json.containsKey(r'repeated_topics'), 'Required key "AnalyticsSummary[repeated_topics]" is missing from JSON.');
        assert(json[r'repeated_topics'] != null, 'Required key "AnalyticsSummary[repeated_topics]" has a null value in JSON.');
        assert(json.containsKey(r'overdue'), 'Required key "AnalyticsSummary[overdue]" is missing from JSON.');
        assert(json[r'overdue'] != null, 'Required key "AnalyticsSummary[overdue]" has a null value in JSON.');
        assert(json.containsKey(r'assignee_load'), 'Required key "AnalyticsSummary[assignee_load]" is missing from JSON.');
        assert(json[r'assignee_load'] != null, 'Required key "AnalyticsSummary[assignee_load]" has a null value in JSON.');
        assert(json.containsKey(r'unassigned_count'), 'Required key "AnalyticsSummary[unassigned_count]" is missing from JSON.');
        assert(json[r'unassigned_count'] != null, 'Required key "AnalyticsSummary[unassigned_count]" has a null value in JSON.');
        return true;
      }());

      return AnalyticsSummary(
        scope: AnalyticsSummaryScopeEnum.fromJson(json[r'scope'])!,
        department: DepartmentRef.fromJson(json[r'department']),
        generatedAt: mapDateTime(json, r'generated_at', r'')!,
        total: mapValueOfType<int>(json, r'total')!,
        closedCount: mapValueOfType<int>(json, r'closed_count')!,
        closedShare: mapValueOfType<double>(json, r'closed_share')!,
        avgFirstResponseHours: mapValueOfType<double>(json, r'avg_first_response_hours'),
        byType: CountByType.listFromJson(json[r'by_type']),
        byCategory: CountByCategory.listFromJson(json[r'by_category']),
        byStatus: CountByStatus.listFromJson(json[r'by_status']),
        newLast24h: AppealRef.listFromJson(json[r'new_last_24h']),
        stuck: StuckAppeal.listFromJson(json[r'stuck']),
        closedLastWeek: AppealRef.listFromJson(json[r'closed_last_week']),
        repeatedTopics: RepeatedTopic.listFromJson(json[r'repeated_topics']),
        overdue: StuckAppeal.listFromJson(json[r'overdue']),
        assigneeLoad: AssigneeLoad.listFromJson(json[r'assignee_load']),
        unassignedCount: mapValueOfType<int>(json, r'unassigned_count')!,
      );
    }
    return null;
  }

  static List<AnalyticsSummary> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AnalyticsSummary>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AnalyticsSummary.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AnalyticsSummary> mapFromJson(dynamic json) {
    final map = <String, AnalyticsSummary>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AnalyticsSummary.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AnalyticsSummary-objects as value to a dart map
  static Map<String, List<AnalyticsSummary>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AnalyticsSummary>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AnalyticsSummary.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'scope',
    'department',
    'generated_at',
    'total',
    'closed_count',
    'closed_share',
    'avg_first_response_hours',
    'by_type',
    'by_category',
    'by_status',
    'new_last_24h',
    'stuck',
    'closed_last_week',
    'repeated_topics',
    'overdue',
    'assignee_load',
    'unassigned_count',
  };
}


enum AnalyticsSummaryScopeEnum {
  company._(r'company'),
  department._(r'department'),
  ;

  /// Instantiate a new enum with the provided value.
  const AnalyticsSummaryScopeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AnalyticsSummaryScopeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AnalyticsSummaryScopeEnum? fromJson(dynamic value) => AnalyticsSummaryScopeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AnalyticsSummaryScopeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AnalyticsSummaryScopeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AnalyticsSummaryScopeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AnalyticsSummaryScopeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AnalyticsSummaryScopeEnum] to String,
/// and [decode] dynamic data back to [AnalyticsSummaryScopeEnum].
class AnalyticsSummaryScopeEnumTypeTransformer {
  factory AnalyticsSummaryScopeEnumTypeTransformer() => _instance ??= const AnalyticsSummaryScopeEnumTypeTransformer._();

  const AnalyticsSummaryScopeEnumTypeTransformer._();

  String encode(AnalyticsSummaryScopeEnum data) => data._value;

  /// Returns the instance of [AnalyticsSummaryScopeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AnalyticsSummaryScopeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AnalyticsSummaryScopeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'company': return AnalyticsSummaryScopeEnum.company;
        case r'department': return AnalyticsSummaryScopeEnum.department;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AnalyticsSummaryScopeEnumTypeTransformer? _instance;
}


