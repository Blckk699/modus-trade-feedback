//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


enum ViewerRelation {
  author._(r'author'),
  participant._(r'participant'),
  assignee._(r'assignee'),
  departmentHead._(r'department_head'),
  owner._(r'owner'),
  admin._(r'admin'),
  ;

  /// Instantiate a new enum with the provided value.
  const ViewerRelation._(this._value);

  /// The underlying value of this enum member.
  final String _value;

  @override
  String toString() => _value;

  /// Encodes this enum as a value suitable for JSON.
  String toJson() => _value;

  /// Returns the instance of [ViewerRelation] that was successfully decoded
  /// from the passed [value] on success, null otherwise.
  static ViewerRelation? fromJson(dynamic value) => ViewerRelationTypeTransformer().decode(value);

  /// Returns a [List] containing instances of [ViewerRelation]
  /// that were successfully decoded from the passed [JSON][json].
  static List<ViewerRelation> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ViewerRelation>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ViewerRelation.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ViewerRelation] to String,
/// and [decode] dynamic data back to [ViewerRelation].
class ViewerRelationTypeTransformer {
  factory ViewerRelationTypeTransformer() => _instance ??= const ViewerRelationTypeTransformer._();

  const ViewerRelationTypeTransformer._();

  /// Encodes this enum as a value suitable for JSON.
  String encode(ViewerRelation data) => data._value;

  /// Returns the instance of [ViewerRelation] that was successfully decoded
  /// from the passed [data] value on success, null otherwise.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ViewerRelation? decode(dynamic data, {bool allowNull = true}) {
    if (data is ViewerRelation) {
      return data;
    }
    if (data != null) {
      switch (data) {
        case r'author': return ViewerRelation.author;
        case r'participant': return ViewerRelation.participant;
        case r'assignee': return ViewerRelation.assignee;
        case r'department_head': return ViewerRelation.departmentHead;
        case r'owner': return ViewerRelation.owner;
        case r'admin': return ViewerRelation.admin;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// The singleton instance of this transformer.
  static ViewerRelationTypeTransformer? _instance;
}

