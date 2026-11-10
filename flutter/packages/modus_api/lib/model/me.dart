//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Me {
  /// Returns a new [Me] instance.
  Me({
    required this.id,
    required this.telegramId,
    required this.fullName,
    required this.position,
    required this.role,
    required this.department,
    required this.isAbsent,
    required this.isDisabled,
    this.responsibleFor = const [],
    this.deputyFor = const [],
    required this.assignedOpenCount,
    required this.permissions,
  });

  int id;

  /// Только для администратора и для самого пользователя
  int? telegramId;

  String fullName;

  /// Должность, например «Сотрудник закупок»
  String? position;

  Role role;

  DepartmentRef? department;

  bool isAbsent;

  bool isDisabled;

  /// Категории, где пользователь — ответственный
  List<CategoryRef> responsibleFor;

  /// Категории, где пользователь — заместитель
  List<CategoryRef> deputyFor;

  /// Открытых обращений, где пользователь — ответственный
  int assignedOpenCount;

  Permissions permissions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Me &&
    other.id == id &&
    other.telegramId == telegramId &&
    other.fullName == fullName &&
    other.position == position &&
    other.role == role &&
    other.department == department &&
    other.isAbsent == isAbsent &&
    other.isDisabled == isDisabled &&
    _deepEquality.equals(other.responsibleFor, responsibleFor) &&
    _deepEquality.equals(other.deputyFor, deputyFor) &&
    other.assignedOpenCount == assignedOpenCount &&
    other.permissions == permissions;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (telegramId == null ? 0 : telegramId!.hashCode) +
    (fullName.hashCode) +
    (position == null ? 0 : position!.hashCode) +
    (role.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (isAbsent.hashCode) +
    (isDisabled.hashCode) +
    (responsibleFor.hashCode) +
    (deputyFor.hashCode) +
    (assignedOpenCount.hashCode) +
    (permissions.hashCode);

  @override
  String toString() => 'Me[id=$id, telegramId=$telegramId, fullName=$fullName, position=$position, role=$role, department=$department, isAbsent=$isAbsent, isDisabled=$isDisabled, responsibleFor=$responsibleFor, deputyFor=$deputyFor, assignedOpenCount=$assignedOpenCount, permissions=$permissions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.telegramId != null) {
      json[r'telegram_id'] = this.telegramId;
    } else {
      json[r'telegram_id'] = null;
    }
      json[r'full_name'] = this.fullName;
    if (this.position != null) {
      json[r'position'] = this.position;
    } else {
      json[r'position'] = null;
    }
      json[r'role'] = this.role;
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
      json[r'is_absent'] = this.isAbsent;
      json[r'is_disabled'] = this.isDisabled;
      json[r'responsible_for'] = this.responsibleFor;
      json[r'deputy_for'] = this.deputyFor;
      json[r'assigned_open_count'] = this.assignedOpenCount;
      json[r'permissions'] = this.permissions;
    return json;
  }

  /// Returns a new [Me] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Me? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "Me[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "Me[id]" has a null value in JSON.');
        assert(json.containsKey(r'telegram_id'), 'Required key "Me[telegram_id]" is missing from JSON.');
        assert(json.containsKey(r'full_name'), 'Required key "Me[full_name]" is missing from JSON.');
        assert(json[r'full_name'] != null, 'Required key "Me[full_name]" has a null value in JSON.');
        assert(json.containsKey(r'position'), 'Required key "Me[position]" is missing from JSON.');
        assert(json.containsKey(r'role'), 'Required key "Me[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "Me[role]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "Me[department]" is missing from JSON.');
        assert(json.containsKey(r'is_absent'), 'Required key "Me[is_absent]" is missing from JSON.');
        assert(json[r'is_absent'] != null, 'Required key "Me[is_absent]" has a null value in JSON.');
        assert(json.containsKey(r'is_disabled'), 'Required key "Me[is_disabled]" is missing from JSON.');
        assert(json[r'is_disabled'] != null, 'Required key "Me[is_disabled]" has a null value in JSON.');
        assert(json.containsKey(r'responsible_for'), 'Required key "Me[responsible_for]" is missing from JSON.');
        assert(json[r'responsible_for'] != null, 'Required key "Me[responsible_for]" has a null value in JSON.');
        assert(json.containsKey(r'deputy_for'), 'Required key "Me[deputy_for]" is missing from JSON.');
        assert(json[r'deputy_for'] != null, 'Required key "Me[deputy_for]" has a null value in JSON.');
        assert(json.containsKey(r'assigned_open_count'), 'Required key "Me[assigned_open_count]" is missing from JSON.');
        assert(json[r'assigned_open_count'] != null, 'Required key "Me[assigned_open_count]" has a null value in JSON.');
        assert(json.containsKey(r'permissions'), 'Required key "Me[permissions]" is missing from JSON.');
        assert(json[r'permissions'] != null, 'Required key "Me[permissions]" has a null value in JSON.');
        return true;
      }());

      return Me(
        id: mapValueOfType<int>(json, r'id')!,
        telegramId: mapValueOfType<int>(json, r'telegram_id'),
        fullName: mapValueOfType<String>(json, r'full_name')!,
        position: mapValueOfType<String>(json, r'position'),
        role: Role.fromJson(json[r'role'])!,
        department: DepartmentRef.fromJson(json[r'department']),
        isAbsent: mapValueOfType<bool>(json, r'is_absent')!,
        isDisabled: mapValueOfType<bool>(json, r'is_disabled')!,
        responsibleFor: CategoryRef.listFromJson(json[r'responsible_for']),
        deputyFor: CategoryRef.listFromJson(json[r'deputy_for']),
        assignedOpenCount: mapValueOfType<int>(json, r'assigned_open_count')!,
        permissions: Permissions.fromJson(json[r'permissions'])!,
      );
    }
    return null;
  }

  static List<Me> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Me>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Me.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Me> mapFromJson(dynamic json) {
    final map = <String, Me>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Me.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Me-objects as value to a dart map
  static Map<String, List<Me>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Me>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Me.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'telegram_id',
    'full_name',
    'position',
    'role',
    'department',
    'is_absent',
    'is_disabled',
    'responsible_for',
    'deputy_for',
    'assigned_open_count',
    'permissions',
  };
}

