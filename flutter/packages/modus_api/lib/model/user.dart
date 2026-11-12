//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class User {
  /// Returns a new [User] instance.
  User({
    required this.id,
    required this.telegramId,
    this.email,
    this.bitrixUserId,
    required this.fullName,
    required this.position,
    required this.role,
    required this.department,
    required this.isAbsent,
    required this.isDisabled,
  });

  int id;

  /// Только для администратора и для самого пользователя
  int? telegramId;

  /// Рабочая почта для входа. Только для администратора и для самого пользователя
  String? email;

  /// ID сотрудника на портале Битрикс24, если он входил через портал. Только для администратора и для самого пользователя 
  int? bitrixUserId;

  String fullName;

  /// Должность, например «Сотрудник закупок»
  String? position;

  Role role;

  DepartmentRef? department;

  bool isAbsent;

  bool isDisabled;

  @override
  bool operator ==(Object other) => identical(this, other) || other is User &&
    other.id == id &&
    other.telegramId == telegramId &&
    other.email == email &&
    other.bitrixUserId == bitrixUserId &&
    other.fullName == fullName &&
    other.position == position &&
    other.role == role &&
    other.department == department &&
    other.isAbsent == isAbsent &&
    other.isDisabled == isDisabled;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (telegramId == null ? 0 : telegramId!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (bitrixUserId == null ? 0 : bitrixUserId!.hashCode) +
    (fullName.hashCode) +
    (position == null ? 0 : position!.hashCode) +
    (role.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (isAbsent.hashCode) +
    (isDisabled.hashCode);

  @override
  String toString() => 'User[id=$id, telegramId=$telegramId, email=$email, bitrixUserId=$bitrixUserId, fullName=$fullName, position=$position, role=$role, department=$department, isAbsent=$isAbsent, isDisabled=$isDisabled]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
    if (this.telegramId != null) {
      json[r'telegram_id'] = this.telegramId;
    } else {
      json[r'telegram_id'] = null;
    }
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.bitrixUserId != null) {
      json[r'bitrix_user_id'] = this.bitrixUserId;
    } else {
      json[r'bitrix_user_id'] = null;
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
    return json;
  }

  /// Returns a new [User] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static User? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "User[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "User[id]" has a null value in JSON.');
        assert(json.containsKey(r'telegram_id'), 'Required key "User[telegram_id]" is missing from JSON.');
        assert(json.containsKey(r'full_name'), 'Required key "User[full_name]" is missing from JSON.');
        assert(json[r'full_name'] != null, 'Required key "User[full_name]" has a null value in JSON.');
        assert(json.containsKey(r'position'), 'Required key "User[position]" is missing from JSON.');
        assert(json.containsKey(r'role'), 'Required key "User[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "User[role]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "User[department]" is missing from JSON.');
        assert(json.containsKey(r'is_absent'), 'Required key "User[is_absent]" is missing from JSON.');
        assert(json[r'is_absent'] != null, 'Required key "User[is_absent]" has a null value in JSON.');
        assert(json.containsKey(r'is_disabled'), 'Required key "User[is_disabled]" is missing from JSON.');
        assert(json[r'is_disabled'] != null, 'Required key "User[is_disabled]" has a null value in JSON.');
        return true;
      }());

      return User(
        id: mapValueOfType<int>(json, r'id')!,
        telegramId: mapValueOfType<int>(json, r'telegram_id'),
        email: mapValueOfType<String>(json, r'email'),
        bitrixUserId: mapValueOfType<int>(json, r'bitrix_user_id'),
        fullName: mapValueOfType<String>(json, r'full_name')!,
        position: mapValueOfType<String>(json, r'position'),
        role: Role.fromJson(json[r'role'])!,
        department: DepartmentRef.fromJson(json[r'department']),
        isAbsent: mapValueOfType<bool>(json, r'is_absent')!,
        isDisabled: mapValueOfType<bool>(json, r'is_disabled')!,
      );
    }
    return null;
  }

  static List<User> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <User>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = User.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, User> mapFromJson(dynamic json) {
    final map = <String, User>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = User.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of User-objects as value to a dart map
  static Map<String, List<User>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<User>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = User.listFromJson(entry.value, growable: growable,);
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
  };
}

