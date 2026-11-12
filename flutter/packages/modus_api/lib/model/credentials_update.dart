//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CredentialsUpdate {
  /// Returns a new [CredentialsUpdate] instance.
  CredentialsUpdate({
    this.email,
    this.newPassword,
    this.currentPassword,
  });

  /// Новая почта; не передано — без изменений
  String? email;

  String? newPassword;

  /// Обязателен, если пароль уже есть
  String? currentPassword;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CredentialsUpdate &&
    other.email == email &&
    other.newPassword == newPassword &&
    other.currentPassword == currentPassword;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (email == null ? 0 : email!.hashCode) +
    (newPassword == null ? 0 : newPassword!.hashCode) +
    (currentPassword == null ? 0 : currentPassword!.hashCode);

  @override
  String toString() => 'CredentialsUpdate[email=$email, newPassword=$newPassword, currentPassword=$currentPassword]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
    if (this.newPassword != null) {
      json[r'new_password'] = this.newPassword;
    } else {
      json[r'new_password'] = null;
    }
    if (this.currentPassword != null) {
      json[r'current_password'] = this.currentPassword;
    } else {
      json[r'current_password'] = null;
    }
    return json;
  }

  /// Returns a new [CredentialsUpdate] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CredentialsUpdate? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return CredentialsUpdate(
        email: mapValueOfType<String>(json, r'email'),
        newPassword: mapValueOfType<String>(json, r'new_password'),
        currentPassword: mapValueOfType<String>(json, r'current_password'),
      );
    }
    return null;
  }

  static List<CredentialsUpdate> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CredentialsUpdate>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CredentialsUpdate.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CredentialsUpdate> mapFromJson(dynamic json) {
    final map = <String, CredentialsUpdate>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CredentialsUpdate.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CredentialsUpdate-objects as value to a dart map
  static Map<String, List<CredentialsUpdate>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CredentialsUpdate>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CredentialsUpdate.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

