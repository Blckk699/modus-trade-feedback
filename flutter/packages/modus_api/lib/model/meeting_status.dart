//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


enum MeetingStatus {
  processing._(r'processing'),
  ready._(r'ready'),
  failed._(r'failed'),
  ;

  /// Instantiate a new enum with the provided value.
  const MeetingStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MeetingStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MeetingStatus? fromJson(dynamic value) => MeetingStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MeetingStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MeetingStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MeetingStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeetingStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MeetingStatus] to String,
/// and [decode] dynamic data back to [MeetingStatus].
class MeetingStatusTypeTransformer {
  factory MeetingStatusTypeTransformer() => _instance ??= const MeetingStatusTypeTransformer._();

  const MeetingStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(MeetingStatus data) => data._value;

  /// Returns the instance of [MeetingStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MeetingStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is MeetingStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'processing': return MeetingStatus.processing;
        case r'ready': return MeetingStatus.ready;
        case r'failed': return MeetingStatus.failed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MeetingStatusTypeTransformer? _instance;
}

