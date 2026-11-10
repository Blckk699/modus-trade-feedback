//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Digest {
  /// Returns a new [Digest] instance.
  Digest({
    required this.scope,
    required this.department,
    required this.generatedAt,
    required this.text,
  });

  DigestScopeEnum scope;

  DepartmentRef? department;

  DateTime generatedAt;

  /// Готовый текст для Telegram, `parse_mode=HTML`
  String text;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Digest &&
    other.scope == scope &&
    other.department == department &&
    other.generatedAt == generatedAt &&
    other.text == text;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (scope.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (generatedAt.hashCode) +
    (text.hashCode);

  @override
  String toString() => 'Digest[scope=$scope, department=$department, generatedAt=$generatedAt, text=$text]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'scope'] = this.scope;
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
      json[r'generated_at'] = this.generatedAt.toUtc().toIso8601String();
      json[r'text'] = this.text;
    return json;
  }

  /// Returns a new [Digest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Digest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'scope'), 'Required key "Digest[scope]" is missing from JSON.');
        assert(json[r'scope'] != null, 'Required key "Digest[scope]" has a null value in JSON.');
        assert(json.containsKey(r'department'), 'Required key "Digest[department]" is missing from JSON.');
        assert(json.containsKey(r'generated_at'), 'Required key "Digest[generated_at]" is missing from JSON.');
        assert(json[r'generated_at'] != null, 'Required key "Digest[generated_at]" has a null value in JSON.');
        assert(json.containsKey(r'text'), 'Required key "Digest[text]" is missing from JSON.');
        assert(json[r'text'] != null, 'Required key "Digest[text]" has a null value in JSON.');
        return true;
      }());

      return Digest(
        scope: DigestScopeEnum.fromJson(json[r'scope'])!,
        department: DepartmentRef.fromJson(json[r'department']),
        generatedAt: mapDateTime(json, r'generated_at', r'')!,
        text: mapValueOfType<String>(json, r'text')!,
      );
    }
    return null;
  }

  static List<Digest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Digest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Digest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Digest> mapFromJson(dynamic json) {
    final map = <String, Digest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Digest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Digest-objects as value to a dart map
  static Map<String, List<Digest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Digest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Digest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'scope',
    'department',
    'generated_at',
    'text',
  };
}


enum DigestScopeEnum {
  company._(r'company'),
  department._(r'department'),
  ;

  /// Instantiate a new enum with the provided value.
  const DigestScopeEnum._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [DigestScopeEnum] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static DigestScopeEnum? fromJson(dynamic value) => DigestScopeEnumTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [DigestScopeEnum]
  /// that were successfully decoded from the passed [JSON][json].
  static List<DigestScopeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DigestScopeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DigestScopeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DigestScopeEnum] to String,
/// and [decode] dynamic data back to [DigestScopeEnum].
class DigestScopeEnumTypeTransformer {
  factory DigestScopeEnumTypeTransformer() => _instance ??= const DigestScopeEnumTypeTransformer._();

  const DigestScopeEnumTypeTransformer._();

  String encode(DigestScopeEnum data) => data._value;

  /// Returns the instance of [DigestScopeEnum] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DigestScopeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data is DigestScopeEnum) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'company': return DigestScopeEnum.company;
        case r'department': return DigestScopeEnum.department;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static DigestScopeEnumTypeTransformer? _instance;
}


