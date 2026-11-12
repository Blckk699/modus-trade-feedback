//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterResult {
  /// Returns a new [RegisterResult] instance.
  RegisterResult({
    required this.status,
    required this.request,
    required this.session,
  });

  /// pending — заявка на рассмотрении, войти нельзя; registered — пользователь создан по приглашению
  RegisterResultStatusEnum status;

  AccessRequest? request;

  Session? session;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterResult &&
    other.status == status &&
    other.request == request &&
    other.session == session;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status.hashCode) +
    (request == null ? 0 : request!.hashCode) +
    (session == null ? 0 : session!.hashCode);

  @override
  String toString() => 'RegisterResult[status=$status, request=$request, session=$session]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'status'] = this.status;
    if (this.request != null) {
      json[r'request'] = this.request;
    } else {
      json[r'request'] = null;
    }
    if (this.session != null) {
      json[r'session'] = this.session;
    } else {
      json[r'session'] = null;
    }
    return json;
  }

  /// Returns a new [RegisterResult] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterResult? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'status'), 'Required key "RegisterResult[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "RegisterResult[status]" has a null value in JSON.');
        assert(json.containsKey(r'request'), 'Required key "RegisterResult[request]" is missing from JSON.');
        assert(json.containsKey(r'session'), 'Required key "RegisterResult[session]" is missing from JSON.');
        return true;
      }());

      return RegisterResult(
        status: RegisterResultStatusEnum.fromJson(json[r'status'])!,
        request: AccessRequest.fromJson(json[r'request']),
        session: Session.fromJson(json[r'session']),
      );
    }
    return null;
  }

  static List<RegisterResult> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterResult>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterResult.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterResult> mapFromJson(dynamic json) {
    final map = <String, RegisterResult>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterResult.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterResult-objects as value to a dart map
  static Map<String, List<RegisterResult>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterResult>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterResult.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'status',
    'request',
    'session',
  };
}

/// pending — заявка на рассмотрении, войти нельзя; registered — пользователь создан по приглашению
enum RegisterResultStatusEnum {
  pending._(r'pending'),
  registered._(r'registered'),
  ;

  /// Instantiate a new enum with the provided value.
  const RegisterResultStatusEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [RegisterResultStatusEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static RegisterResultStatusEnum? fromJson(dynamic value) => RegisterResultStatusEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [RegisterResultStatusEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<RegisterResultStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterResultStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterResultStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RegisterResultStatusEnum] to String,
/// and [decode] dynamic data back to [RegisterResultStatusEnum].
class RegisterResultStatusEnumTypeTransformer {
  factory RegisterResultStatusEnumTypeTransformer() => _instance ??= const RegisterResultStatusEnumTypeTransformer._();

  const RegisterResultStatusEnumTypeTransformer._();

  String encode(RegisterResultStatusEnum data) => data._value;

  /// Returns the instance of [RegisterResultStatusEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RegisterResultStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is RegisterResultStatusEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'pending': return RegisterResultStatusEnum.pending;
        case r'registered': return RegisterResultStatusEnum.registered;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static RegisterResultStatusEnumTypeTransformer? _instance;
}


