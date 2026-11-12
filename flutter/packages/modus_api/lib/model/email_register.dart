//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class EmailRegister {
  /// Returns a new [EmailRegister] instance.
  EmailRegister({
    required this.fullName,
    required this.email,
    required this.password,
    this.departmentId,
    this.comment,
    this.inviteToken,
  });

  String fullName;

  /// Рабочая почта, уникальна без учёта регистра
  String email;

  String password;

  /// Из `GET /access-requests/departments`
  int? departmentId;

  /// Должность или комментарий
  String? comment;

  /// Токен из ссылки `https://<домен>/invite/<токен>`; с ним — сразу вход без заявки
  String? inviteToken;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EmailRegister &&
    other.fullName == fullName &&
    other.email == email &&
    other.password == password &&
    other.departmentId == departmentId &&
    other.comment == comment &&
    other.inviteToken == inviteToken;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fullName.hashCode) +
    (email.hashCode) +
    (password.hashCode) +
    (departmentId == null ? 0 : departmentId!.hashCode) +
    (comment == null ? 0 : comment!.hashCode) +
    (inviteToken == null ? 0 : inviteToken!.hashCode);

  @override
  String toString() => 'EmailRegister[fullName=$fullName, email=$email, password=$password, departmentId=$departmentId, comment=$comment, inviteToken=$inviteToken]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'full_name'] = this.fullName;
      json[r'email'] = this.email;
      json[r'password'] = this.password;
    if (this.departmentId != null) {
      json[r'department_id'] = this.departmentId;
    } else {
      json[r'department_id'] = null;
    }
    if (this.comment != null) {
      json[r'comment'] = this.comment;
    } else {
      json[r'comment'] = null;
    }
    if (this.inviteToken != null) {
      json[r'invite_token'] = this.inviteToken;
    } else {
      json[r'invite_token'] = null;
    }
    return json;
  }

  /// Returns a new [EmailRegister] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EmailRegister? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'full_name'), 'Required key "EmailRegister[full_name]" is missing from JSON.');
        assert(json[r'full_name'] != null, 'Required key "EmailRegister[full_name]" has a null value in JSON.');
        assert(json.containsKey(r'email'), 'Required key "EmailRegister[email]" is missing from JSON.');
        assert(json[r'email'] != null, 'Required key "EmailRegister[email]" has a null value in JSON.');
        assert(json.containsKey(r'password'), 'Required key "EmailRegister[password]" is missing from JSON.');
        assert(json[r'password'] != null, 'Required key "EmailRegister[password]" has a null value in JSON.');
        return true;
      }());

      return EmailRegister(
        fullName: mapValueOfType<String>(json, r'full_name')!,
        email: mapValueOfType<String>(json, r'email')!,
        password: mapValueOfType<String>(json, r'password')!,
        departmentId: mapValueOfType<int>(json, r'department_id'),
        comment: mapValueOfType<String>(json, r'comment'),
        inviteToken: mapValueOfType<String>(json, r'invite_token'),
      );
    }
    return null;
  }

  static List<EmailRegister> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <EmailRegister>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EmailRegister.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EmailRegister> mapFromJson(dynamic json) {
    final map = <String, EmailRegister>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EmailRegister.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EmailRegister-objects as value to a dart map
  static Map<String, List<EmailRegister>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<EmailRegister>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EmailRegister.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'full_name',
    'email',
    'password',
  };
}

