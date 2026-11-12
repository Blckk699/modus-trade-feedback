//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AccessRequest {
  /// Returns a new [AccessRequest] instance.
  AccessRequest({
    required this.id,
    required this.status,
    required this.fullName,
    required this.email,
    required this.telegramUsername,
    required this.department,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.assignedRole,
    required this.assignedDepartment,
    required this.decidedBy,
    required this.decidedAt,
    required this.rejectReason,
    required this.userId,
  });

  int id;

  AccessRequestStatus status;

  String fullName;

  /// Почта, если заявка подана регистрацией по почте; иначе заявка из Telegram
  String? email;

  String? telegramUsername;

  /// Подразделение, которое выбрал заявитель
  DepartmentRef? department;

  String? comment;

  DateTime createdAt;

  DateTime updatedAt;

  /// Роль, выданная при одобрении
  AccessRequestAssignedRoleEnum? assignedRole;

  /// Подразделение, назначенное при одобрении
  DepartmentRef? assignedDepartment;

  UserBrief? decidedBy;

  DateTime? decidedAt;

  String? rejectReason;

  /// Созданный пользователь (после одобрения)
  int? userId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AccessRequest &&
    other.id == id &&
    other.status == status &&
    other.fullName == fullName &&
    other.email == email &&
    other.telegramUsername == telegramUsername &&
    other.department == department &&
    other.comment == comment &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.assignedRole == assignedRole &&
    other.assignedDepartment == assignedDepartment &&
    other.decidedBy == decidedBy &&
    other.decidedAt == decidedAt &&
    other.rejectReason == rejectReason &&
    other.userId == userId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (status.hashCode) +
    (fullName.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (telegramUsername == null ? 0 : telegramUsername!.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (comment == null ? 0 : comment!.hashCode) +
    (createdAt.hashCode) +
    (updatedAt.hashCode) +
    (assignedRole == null ? 0 : assignedRole!.hashCode) +
    (assignedDepartment == null ? 0 : assignedDepartment!.hashCode) +
    (decidedBy == null ? 0 : decidedBy!.hashCode) +
    (decidedAt == null ? 0 : decidedAt!.hashCode) +
    (rejectReason == null ? 0 : rejectReason!.hashCode) +
    (userId == null ? 0 : userId!.hashCode);

  @override
  String toString() => 'AccessRequest[id=$id, status=$status, fullName=$fullName, email=$email, telegramUsername=$telegramUsername, department=$department, comment=$comment, createdAt=$createdAt, updatedAt=$updatedAt, assignedRole=$assignedRole, assignedDepartment=$assignedDepartment, decidedBy=$decidedBy, decidedAt=$decidedAt, rejectReason=$rejectReason, userId=$userId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'status'] = this.status;
      json[r'full_name'] = this.fullName;
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.telegramUsername != null) {
      json[r'telegram_username'] = this.telegramUsername;
    } else {
      json[r'telegram_username'] = null;
    }
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
    if (this.comment != null) {
      json[r'comment'] = this.comment;
    } else {
      json[r'comment'] = null;
    }
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'updated_at'] = this.updatedAt.toUtc().toIso8601String();
    if (this.assignedRole != null) {
      json[r'assigned_role'] = this.assignedRole;
    } else {
      json[r'assigned_role'] = null;
    }
    if (this.assignedDepartment != null) {
      json[r'assigned_department'] = this.assignedDepartment;
    } else {
      json[r'assigned_department'] = null;
    }
    if (this.decidedBy != null) {
      json[r'decided_by'] = this.decidedBy;
    } else {
      json[r'decided_by'] = null;
    }
    if (this.decidedAt != null) {
      json[r'decided_at'] = this.decidedAt!.toUtc().toIso8601String();
    } else {
      json[r'decided_at'] = null;
    }
    if (this.rejectReason != null) {
      json[r'reject_reason'] = this.rejectReason;
    } else {
      json[r'reject_reason'] = null;
    }
    if (this.userId != null) {
      json[r'user_id'] = this.userId;
    } else {
      json[r'user_id'] = null;
    }
    return json;
  }

  /// Returns a new [AccessRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AccessRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "AccessRequest[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "AccessRequest[id]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "AccessRequest[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "AccessRequest[status]" has a null value in JSON.');
        assert(json.containsKey(r'full_name'), 'Required key "AccessRequest[full_name]" is missing from JSON.');
        assert(json[r'full_name'] != null, 'Required key "AccessRequest[full_name]" has a null value in JSON.');
        assert(json.containsKey(r'email'), 'Required key "AccessRequest[email]" is missing from JSON.');
        assert(json.containsKey(r'telegram_username'), 'Required key "AccessRequest[telegram_username]" is missing from JSON.');
        assert(json.containsKey(r'department'), 'Required key "AccessRequest[department]" is missing from JSON.');
        assert(json.containsKey(r'comment'), 'Required key "AccessRequest[comment]" is missing from JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "AccessRequest[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "AccessRequest[created_at]" has a null value in JSON.');
        assert(json.containsKey(r'updated_at'), 'Required key "AccessRequest[updated_at]" is missing from JSON.');
        assert(json[r'updated_at'] != null, 'Required key "AccessRequest[updated_at]" has a null value in JSON.');
        assert(json.containsKey(r'assigned_role'), 'Required key "AccessRequest[assigned_role]" is missing from JSON.');
        assert(json.containsKey(r'assigned_department'), 'Required key "AccessRequest[assigned_department]" is missing from JSON.');
        assert(json.containsKey(r'decided_by'), 'Required key "AccessRequest[decided_by]" is missing from JSON.');
        assert(json.containsKey(r'decided_at'), 'Required key "AccessRequest[decided_at]" is missing from JSON.');
        assert(json.containsKey(r'reject_reason'), 'Required key "AccessRequest[reject_reason]" is missing from JSON.');
        assert(json.containsKey(r'user_id'), 'Required key "AccessRequest[user_id]" is missing from JSON.');
        return true;
      }());

      return AccessRequest(
        id: mapValueOfType<int>(json, r'id')!,
        status: AccessRequestStatus.fromJson(json[r'status'])!,
        fullName: mapValueOfType<String>(json, r'full_name')!,
        email: mapValueOfType<String>(json, r'email'),
        telegramUsername: mapValueOfType<String>(json, r'telegram_username'),
        department: DepartmentRef.fromJson(json[r'department']),
        comment: mapValueOfType<String>(json, r'comment'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
        updatedAt: mapDateTime(json, r'updated_at', r'')!,
        assignedRole: AccessRequestAssignedRoleEnum.fromJson(json[r'assigned_role']),
        assignedDepartment: DepartmentRef.fromJson(json[r'assigned_department']),
        decidedBy: UserBrief.fromJson(json[r'decided_by']),
        decidedAt: mapDateTime(json, r'decided_at', r''),
        rejectReason: mapValueOfType<String>(json, r'reject_reason'),
        userId: mapValueOfType<int>(json, r'user_id'),
      );
    }
    return null;
  }

  static List<AccessRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AccessRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AccessRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AccessRequest> mapFromJson(dynamic json) {
    final map = <String, AccessRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AccessRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AccessRequest-objects as value to a dart map
  static Map<String, List<AccessRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AccessRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AccessRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'status',
    'full_name',
    'email',
    'telegram_username',
    'department',
    'comment',
    'created_at',
    'updated_at',
    'assigned_role',
    'assigned_department',
    'decided_by',
    'decided_at',
    'reject_reason',
    'user_id',
  };
}

/// Роль, выданная при одобрении
enum AccessRequestAssignedRoleEnum {
  employee._(r'employee'),
  head._(r'head'),
  admin._(r'admin'),
  ;

  /// Instantiate a new enum with the provided value.
  const AccessRequestAssignedRoleEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AccessRequestAssignedRoleEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AccessRequestAssignedRoleEnum? fromJson(dynamic value) => AccessRequestAssignedRoleEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AccessRequestAssignedRoleEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AccessRequestAssignedRoleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AccessRequestAssignedRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AccessRequestAssignedRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AccessRequestAssignedRoleEnum] to String,
/// and [decode] dynamic data back to [AccessRequestAssignedRoleEnum].
class AccessRequestAssignedRoleEnumTypeTransformer {
  factory AccessRequestAssignedRoleEnumTypeTransformer() => _instance ??= const AccessRequestAssignedRoleEnumTypeTransformer._();

  const AccessRequestAssignedRoleEnumTypeTransformer._();

  String encode(AccessRequestAssignedRoleEnum data) => data._value;

  /// Returns the instance of [AccessRequestAssignedRoleEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AccessRequestAssignedRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AccessRequestAssignedRoleEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'employee': return AccessRequestAssignedRoleEnum.employee;
        case r'head': return AccessRequestAssignedRoleEnum.head;
        case r'admin': return AccessRequestAssignedRoleEnum.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AccessRequestAssignedRoleEnumTypeTransformer? _instance;
}


