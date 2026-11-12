//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AccessStatus {
  /// Returns a new [AccessStatus] instance.
  AccessStatus({
    required this.state,
    required this.request,
  });

  /// none — заявки нет, показать форму; pending — на рассмотрении; rejected — последняя заявка отклонена (можно подать новую); registered — пользователь заведён, нужно войти; disabled — доступ отключён 
  AccessStatusStateEnum state;

  /// Последняя заявка аккаунта
  AccessRequest? request;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AccessStatus &&
    other.state == state &&
    other.request == request;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (state.hashCode) +
    (request == null ? 0 : request!.hashCode);

  @override
  String toString() => 'AccessStatus[state=$state, request=$request]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'state'] = this.state;
    if (this.request != null) {
      json[r'request'] = this.request;
    } else {
      json[r'request'] = null;
    }
    return json;
  }

  /// Returns a new [AccessStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AccessStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'state'), 'Required key "AccessStatus[state]" is missing from JSON.');
        assert(json[r'state'] != null, 'Required key "AccessStatus[state]" has a null value in JSON.');
        assert(json.containsKey(r'request'), 'Required key "AccessStatus[request]" is missing from JSON.');
        return true;
      }());

      return AccessStatus(
        state: AccessStatusStateEnum.fromJson(json[r'state'])!,
        request: AccessRequest.fromJson(json[r'request']),
      );
    }
    return null;
  }

  static List<AccessStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AccessStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AccessStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AccessStatus> mapFromJson(dynamic json) {
    final map = <String, AccessStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AccessStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AccessStatus-objects as value to a dart map
  static Map<String, List<AccessStatus>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AccessStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AccessStatus.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'state',
    'request',
  };
}

/// none — заявки нет, показать форму; pending — на рассмотрении; rejected — последняя заявка отклонена (можно подать новую); registered — пользователь заведён, нужно войти; disabled — доступ отключён 
enum AccessStatusStateEnum {
  none._(r'none'),
  pending._(r'pending'),
  rejected._(r'rejected'),
  registered._(r'registered'),
  disabled._(r'disabled'),
  ;

  /// Instantiate a new enum with the provided value.
  const AccessStatusStateEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [AccessStatusStateEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static AccessStatusStateEnum? fromJson(dynamic value) => AccessStatusStateEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [AccessStatusStateEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<AccessStatusStateEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AccessStatusStateEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AccessStatusStateEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AccessStatusStateEnum] to String,
/// and [decode] dynamic data back to [AccessStatusStateEnum].
class AccessStatusStateEnumTypeTransformer {
  factory AccessStatusStateEnumTypeTransformer() => _instance ??= const AccessStatusStateEnumTypeTransformer._();

  const AccessStatusStateEnumTypeTransformer._();

  String encode(AccessStatusStateEnum data) => data._value;

  /// Returns the instance of [AccessStatusStateEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AccessStatusStateEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is AccessStatusStateEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'none': return AccessStatusStateEnum.none;
        case r'pending': return AccessStatusStateEnum.pending;
        case r'rejected': return AccessStatusStateEnum.rejected;
        case r'registered': return AccessStatusStateEnum.registered;
        case r'disabled': return AccessStatusStateEnum.disabled;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static AccessStatusStateEnumTypeTransformer? _instance;
}


