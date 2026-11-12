//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class InviteAccepted {
  /// Returns a new [InviteAccepted] instance.
  InviteAccepted({
    required this.created,
    required this.user,
    required this.session,
  });

  /// true — пользователь создан по приглашению; false — уже был, ничего не изменилось
  bool created;

  Me user;

  /// Для Mini App и веба; боту — `null`
  SessionToken? session;

  @override
  bool operator ==(Object other) => identical(this, other) || other is InviteAccepted &&
    other.created == created &&
    other.user == user &&
    other.session == session;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (created.hashCode) +
    (user.hashCode) +
    (session == null ? 0 : session!.hashCode);

  @override
  String toString() => 'InviteAccepted[created=$created, user=$user, session=$session]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'created'] = this.created;
      json[r'user'] = this.user;
    if (this.session != null) {
      json[r'session'] = this.session;
    } else {
      json[r'session'] = null;
    }
    return json;
  }

  /// Returns a new [InviteAccepted] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static InviteAccepted? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'created'), 'Required key "InviteAccepted[created]" is missing from JSON.');
        assert(json[r'created'] != null, 'Required key "InviteAccepted[created]" has a null value in JSON.');
        assert(json.containsKey(r'user'), 'Required key "InviteAccepted[user]" is missing from JSON.');
        assert(json[r'user'] != null, 'Required key "InviteAccepted[user]" has a null value in JSON.');
        assert(json.containsKey(r'session'), 'Required key "InviteAccepted[session]" is missing from JSON.');
        return true;
      }());

      return InviteAccepted(
        created: mapValueOfType<bool>(json, r'created')!,
        user: Me.fromJson(json[r'user'])!,
        session: SessionToken.fromJson(json[r'session']),
      );
    }
    return null;
  }

  static List<InviteAccepted> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InviteAccepted>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InviteAccepted.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, InviteAccepted> mapFromJson(dynamic json) {
    final map = <String, InviteAccepted>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = InviteAccepted.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of InviteAccepted-objects as value to a dart map
  static Map<String, List<InviteAccepted>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<InviteAccepted>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = InviteAccepted.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'created',
    'user',
    'session',
  };
}

