//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// active — действует; expired — истёк срок; revoked — отозвано; exhausted — использования кончились
enum InviteState {
  active._(r'active'),
  expired._(r'expired'),
  revoked._(r'revoked'),
  exhausted._(r'exhausted'),
  ;

  /// Instantiate a new enum with the provided value.
  const InviteState._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [InviteState] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static InviteState? fromJson(dynamic value) => InviteStateTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [InviteState]
  /// that were successfully decoded from the passed [JSON][json].
  static List<InviteState> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <InviteState>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = InviteState.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [InviteState] to String,
/// and [decode] dynamic data back to [InviteState].
class InviteStateTypeTransformer {
  factory InviteStateTypeTransformer() => _instance ??= const InviteStateTypeTransformer._();

  const InviteStateTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(InviteState data) => data._value;

  /// Returns the instance of [InviteState] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  InviteState? decode(dynamic data, {bool allowNull = true}) {
    if (data is InviteState) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'active': return InviteState.active;
        case r'expired': return InviteState.expired;
        case r'revoked': return InviteState.revoked;
        case r'exhausted': return InviteState.exhausted;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static InviteStateTypeTransformer? _instance;
}

