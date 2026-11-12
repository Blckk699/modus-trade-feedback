//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InviteCreated {
  /// Returns a new [InviteCreated] instance.
  InviteCreated({
    required this.id,
    required this.state,
    required this.role,
    required this.department,
    required this.fullName,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    required this.usedCount,
    required this.revokedAt,
    required this.token,
    required this.botLink,
    required this.webLink,
  });

  int id;

  InviteState state;

  AssignableRole role;

  DepartmentRef? department;

  String? fullName;

  UserBrief createdBy;

  DateTime createdAt;

  DateTime expiresAt;

  int maxUses;

  int usedCount;

  DateTime? revokedAt;

  /// Показывается один раз, в базе — только хеш
  String token;

  /// `https://t.me/<бот>?start=inv_<токен>`
  String botLink;

  /// `https://<домен>/invite/<токен>`
  String webLink;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InviteCreated &&
    other.id == id &&
    other.state == state &&
    other.role == role &&
    other.department == department &&
    other.fullName == fullName &&
    other.createdBy == createdBy &&
    other.createdAt == createdAt &&
    other.expiresAt == expiresAt &&
    other.maxUses == maxUses &&
    other.usedCount == usedCount &&
    other.revokedAt == revokedAt &&
    other.token == token &&
    other.botLink == botLink &&
    other.webLink == webLink;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (state.hashCode) +
    (role.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (fullName == null ? 0 : fullName!.hashCode) +
    (createdBy.hashCode) +
    (createdAt.hashCode) +
    (expiresAt.hashCode) +
    (maxUses.hashCode) +
    (usedCount.hashCode) +
    (revokedAt == null ? 0 : revokedAt!.hashCode) +
    (token.hashCode) +
    (botLink.hashCode) +
    (webLink.hashCode);

  @override
  String toString() => 'InviteCreated[id=$id, state=$state, role=$role, department=$department, fullName=$fullName, createdBy=$createdBy, createdAt=$createdAt, expiresAt=$expiresAt, maxUses=$maxUses, usedCount=$usedCount, revokedAt=$revokedAt, token=$token, botLink=$botLink, webLink=$webLink]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'state'] = this.state;
      json[r'role'] = this.role;
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
    if (this.fullName != null) {
      json[r'full_name'] = this.fullName;
    } else {
      json[r'full_name'] = null;
    }
      json[r'created_by'] = this.createdBy;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'expires_at'] = this.expiresAt.toUtc().toIso8601String();
      json[r'max_uses'] = this.maxUses;
      json[r'used_count'] = this.usedCount;
    if (this.revokedAt != null) {
      json[r'revoked_at'] = this.revokedAt!.toUtc().toIso8601String();
    } else {
      json[r'revoked_at'] = null;
    }
      json[r'token'] = this.token;
      json[r'bot_link'] = this.botLink;
      json[r'web_link'] = this.webLink;
    return json;
  }

  /// Returns a new [InviteCreated] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InviteCreated? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'id'), 'Required key "InviteCreated[id]" is missing from JSON.');
        assert(json[r'id'] != null, 'Required key "InviteCreated[id]" has a null value in JSON.');
        assert(json.containsKey(r'state'), 'Required key "InviteCreated[state]" is missing from JSON.');
        assert(json[r'state'] != null, 'Required key "InviteCreated[state]" has a null value in JSON.');
        assert(json.containsKey(r'role'), 'Required key "InviteCreated[role]" is missing from JSON.');
        assert(json[r'role'] != null, 'Required key "InviteCreated[role]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "InviteCreated[department]" is missing from JSON.');
        assert(json.containsKey(r'full_name'), 'Required key "InviteCreated[full_name]" is missing from JSON.');
        assert(json.containsKey(r'created_by'), 'Required key "InviteCreated[created_by]" is missing from JSON.');
        assert(json[r'created_by'] != null, 'Required key "InviteCreated[created_by]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "InviteCreated[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "InviteCreated[created_at]" has a null value in JSON.');
        assert(json.containsKey(r'expires_at'), 'Required key "InviteCreated[expires_at]" is missing from JSON.');
        assert(json[r'expires_at'] != null, 'Required key "InviteCreated[expires_at]" has a null value in JSON.');
        assert(json.containsKey(r'max_uses'), 'Required key "InviteCreated[max_uses]" is missing from JSON.');
        assert(json[r'max_uses'] != null, 'Required key "InviteCreated[max_uses]" has a null value in JSON.');
        assert(json.containsKey(r'used_count'), 'Required key "InviteCreated[used_count]" is missing from JSON.');
        assert(json[r'used_count'] != null, 'Required key "InviteCreated[used_count]" has a null value in JSON.');
        assert(json.containsKey(r'revoked_at'), 'Required key "InviteCreated[revoked_at]" is missing from JSON.');
        assert(json.containsKey(r'token'), 'Required key "InviteCreated[token]" is missing from JSON.');
        assert(json[r'token'] != null, 'Required key "InviteCreated[token]" has a null value in JSON.');
        assert(json.containsKey(r'bot_link'), 'Required key "InviteCreated[bot_link]" is missing from JSON.');
        assert(json[r'bot_link'] != null, 'Required key "InviteCreated[bot_link]" has a null value in JSON.');
        assert(json.containsKey(r'web_link'), 'Required key "InviteCreated[web_link]" is missing from JSON.');
        assert(json[r'web_link'] != null, 'Required key "InviteCreated[web_link]" has a null value in JSON.');
        return true;
      }());

      return InviteCreated(
        id: mapValueOfType<int>(json, r'id')!,
        state: InviteState.fromJson(json[r'state'])!,
        role: AssignableRole.fromJson(json[r'role'])!,
        department: DepartmentRef.fromJson(json[r'department']),
        fullName: mapValueOfType<String>(json, r'full_name'),
        createdBy: UserBrief.fromJson(json[r'created_by'])!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
        expiresAt: mapDateTime(json, r'expires_at', r'')!,
        maxUses: mapValueOfType<int>(json, r'max_uses')!,
        usedCount: mapValueOfType<int>(json, r'used_count')!,
        revokedAt: mapDateTime(json, r'revoked_at', r''),
        token: mapValueOfType<String>(json, r'token')!,
        botLink: mapValueOfType<String>(json, r'bot_link')!,
        webLink: mapValueOfType<String>(json, r'web_link')!,
      );
    }
    return null;
  }

  static List<InviteCreated> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InviteCreated>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InviteCreated.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InviteCreated> mapFromJson(dynamic json) {
    final map = <String, InviteCreated>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InviteCreated.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InviteCreated-objects as value to a dart map
  static Map<String, List<InviteCreated>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InviteCreated>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InviteCreated.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'state',
    'role',
    'department',
    'full_name',
    'created_by',
    'created_at',
    'expires_at',
    'max_uses',
    'used_count',
    'revoked_at',
    'token',
    'bot_link',
    'web_link',
  };
}

