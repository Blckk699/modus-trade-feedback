//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


enum MeetingDraftStatus {
  pending._(r'pending'),
  confirmed._(r'confirmed'),
  discarded._(r'discarded'),
  ;

  /// Instantiate a new enum with the provided value.
  const MeetingDraftStatus._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [MeetingDraftStatus] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static MeetingDraftStatus? fromJson(dynamic value) => MeetingDraftStatusTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [MeetingDraftStatus]
  /// that were successfully decoded from the passed [JSON][json].
  static List<MeetingDraftStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MeetingDraftStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MeetingDraftStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MeetingDraftStatus] to String,
/// and [decode] dynamic data back to [MeetingDraftStatus].
class MeetingDraftStatusTypeTransformer {
  factory MeetingDraftStatusTypeTransformer() => _instance ??= const MeetingDraftStatusTypeTransformer._();

  const MeetingDraftStatusTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(MeetingDraftStatus data) => data._value;

  /// Returns the instance of [MeetingDraftStatus] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MeetingDraftStatus? decode(dynamic data, {bool allowNull = true}) {
    if (data is MeetingDraftStatus) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'pending': return MeetingDraftStatus.pending;
        case r'confirmed': return MeetingDraftStatus.confirmed;
        case r'discarded': return MeetingDraftStatus.discarded;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static MeetingDraftStatusTypeTransformer? _instance;
}

