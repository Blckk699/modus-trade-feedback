//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


enum NameConsent {
  pending._(r'pending'),
  shown._(r'shown'),
  hidden._(r'hidden'),
  ;

  /// Instantiate a new enum with the provided value.
  const NameConsent._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [NameConsent] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static NameConsent? fromJson(dynamic value) => NameConsentTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [NameConsent]
  /// that were successfully decoded from the passed [JSON][json].
  static List<NameConsent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NameConsent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NameConsent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [NameConsent] to String,
/// and [decode] dynamic data back to [NameConsent].
class NameConsentTypeTransformer {
  factory NameConsentTypeTransformer() => _instance ??= const NameConsentTypeTransformer._();

  const NameConsentTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(NameConsent data) => data._value;

  /// Returns the instance of [NameConsent] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  NameConsent? decode(dynamic data, {bool allowNull = true}) {
    if (data is NameConsent) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'pending': return NameConsent.pending;
        case r'shown': return NameConsent.shown;
        case r'hidden': return NameConsent.hidden;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static NameConsentTypeTransformer? _instance;
}

