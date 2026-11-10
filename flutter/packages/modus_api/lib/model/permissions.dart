//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Permissions {
  /// Returns a new [Permissions] instance.
  Permissions({
    required this.canCreateAppeal,
    required this.canProcessAppeals,
    required this.canViewDepartment,
    required this.canViewAllAppeals,
    required this.analyticsScope,
    required this.canUploadMeetings,
    required this.canManageSettings,
    required this.canViewUnassigned,
  });

  bool canCreateAppeal;

  /// Есть очередь назначенных (ответственный по категории или по обращению), руководитель или собственник
  bool canProcessAppeals;

  bool canViewDepartment;

  bool canViewAllAppeals;

  PermissionsAnalyticsScopeEnum analyticsScope;

  bool canUploadMeetings;

  bool canManageSettings;

  bool canViewUnassigned;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Permissions &&
    other.canCreateAppeal == canCreateAppeal &&
    other.canProcessAppeals == canProcessAppeals &&
    other.canViewDepartment == canViewDepartment &&
    other.canViewAllAppeals == canViewAllAppeals &&
    other.analyticsScope == analyticsScope &&
    other.canUploadMeetings == canUploadMeetings &&
    other.canManageSettings == canManageSettings &&
    other.canViewUnassigned == canViewUnassigned;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (canCreateAppeal.hashCode) +
    (canProcessAppeals.hashCode) +
    (canViewDepartment.hashCode) +
    (canViewAllAppeals.hashCode) +
    (analyticsScope.hashCode) +
    (canUploadMeetings.hashCode) +
    (canManageSettings.hashCode) +
    (canViewUnassigned.hashCode);

  @override
  String toString() => 'Permissions[canCreateAppeal=$canCreateAppeal, canProcessAppeals=$canProcessAppeals, canViewDepartment=$canViewDepartment, canViewAllAppeals=$canViewAllAppeals, analyticsScope=$analyticsScope, canUploadMeetings=$canUploadMeetings, canManageSettings=$canManageSettings, canViewUnassigned=$canViewUnassigned]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'can_create_appeal'] = this.canCreateAppeal;
      json[r'can_process_appeals'] = this.canProcessAppeals;
      json[r'can_view_department'] = this.canViewDepartment;
      json[r'can_view_all_appeals'] = this.canViewAllAppeals;
      json[r'analytics_scope'] = this.analyticsScope;
      json[r'can_upload_meetings'] = this.canUploadMeetings;
      json[r'can_manage_settings'] = this.canManageSettings;
      json[r'can_view_unassigned'] = this.canViewUnassigned;
    return json;
  }

  /// Returns a new [Permissions] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Permissions? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'can_create_appeal'), 'Required key "Permissions[can_create_appeal]" is missing from JSON.');
        assert(json[r'can_create_appeal'] != null, 'Required key "Permissions[can_create_appeal]" has a null value in JSON.');
        assert(json.containsKey(r'can_process_appeals'), 'Required key "Permissions[can_process_appeals]" is missing from JSON.');
        assert(json[r'can_process_appeals'] != null, 'Required key "Permissions[can_process_appeals]" has a null value in JSON.');
        assert(json.containsKey(r'can_view_department'), 'Required key "Permissions[can_view_department]" is missing from JSON.');
        assert(json[r'can_view_department'] != null, 'Required key "Permissions[can_view_department]" has a null value in JSON.');
        assert(json.containsKey(r'can_view_all_appeals'), 'Required key "Permissions[can_view_all_appeals]" is missing from JSON.');
        assert(json[r'can_view_all_appeals'] != null, 'Required key "Permissions[can_view_all_appeals]" has a null value in JSON.');
        assert(json.containsKey(r'analytics_scope'), 'Required key "Permissions[analytics_scope]" is missing from JSON.');
        assert(json[r'analytics_scope'] != null, 'Required key "Permissions[analytics_scope]" has a null value in JSON.');
        assert(json.containsKey(r'can_upload_meetings'), 'Required key "Permissions[can_upload_meetings]" is missing from JSON.');
        assert(json[r'can_upload_meetings'] != null, 'Required key "Permissions[can_upload_meetings]" has a null value in JSON.');
        assert(json.containsKey(r'can_manage_settings'), 'Required key "Permissions[can_manage_settings]" is missing from JSON.');
        assert(json[r'can_manage_settings'] != null, 'Required key "Permissions[can_manage_settings]" has a null value in JSON.');
        assert(json.containsKey(r'can_view_unassigned'), 'Required key "Permissions[can_view_unassigned]" is missing from JSON.');
        assert(json[r'can_view_unassigned'] != null, 'Required key "Permissions[can_view_unassigned]" has a null value in JSON.');
        return true;
      }());

      return Permissions(
        canCreateAppeal: mapValueOfType<bool>(json, r'can_create_appeal')!,
        canProcessAppeals: mapValueOfType<bool>(json, r'can_process_appeals')!,
        canViewDepartment: mapValueOfType<bool>(json, r'can_view_department')!,
        canViewAllAppeals: mapValueOfType<bool>(json, r'can_view_all_appeals')!,
        analyticsScope: PermissionsAnalyticsScopeEnum.fromJson(json[r'analytics_scope'])!,
        canUploadMeetings: mapValueOfType<bool>(json, r'can_upload_meetings')!,
        canManageSettings: mapValueOfType<bool>(json, r'can_manage_settings')!,
        canViewUnassigned: mapValueOfType<bool>(json, r'can_view_unassigned')!,
      );
    }
    return null;
  }

  static List<Permissions> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Permissions>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Permissions.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Permissions> mapFromJson(dynamic json) {
    final map = <String, Permissions>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Permissions.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Permissions-objects as value to a dart map
  static Map<String, List<Permissions>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Permissions>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Permissions.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'can_create_appeal',
    'can_process_appeals',
    'can_view_department',
    'can_view_all_appeals',
    'analytics_scope',
    'can_upload_meetings',
    'can_manage_settings',
    'can_view_unassigned',
  };
}


enum PermissionsAnalyticsScopeEnum {
  none._(r'none'),
  department._(r'department'),
  company._(r'company'),
  ;

  /// Instantiate a new enum with the provided value.
  const PermissionsAnalyticsScopeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [PermissionsAnalyticsScopeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static PermissionsAnalyticsScopeEnum? fromJson(dynamic value) => PermissionsAnalyticsScopeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [PermissionsAnalyticsScopeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<PermissionsAnalyticsScopeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PermissionsAnalyticsScopeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PermissionsAnalyticsScopeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PermissionsAnalyticsScopeEnum] to String,
/// and [decode] dynamic data back to [PermissionsAnalyticsScopeEnum].
class PermissionsAnalyticsScopeEnumTypeTransformer {
  factory PermissionsAnalyticsScopeEnumTypeTransformer() => _instance ??= const PermissionsAnalyticsScopeEnumTypeTransformer._();

  const PermissionsAnalyticsScopeEnumTypeTransformer._();

  String encode(PermissionsAnalyticsScopeEnum data) => data._value;

  /// Returns the instance of [PermissionsAnalyticsScopeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PermissionsAnalyticsScopeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is PermissionsAnalyticsScopeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'none': return PermissionsAnalyticsScopeEnum.none;
        case r'department': return PermissionsAnalyticsScopeEnum.department;
        case r'company': return PermissionsAnalyticsScopeEnum.company;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static PermissionsAnalyticsScopeEnumTypeTransformer? _instance;
}


