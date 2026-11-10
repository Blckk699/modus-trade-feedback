//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FeedItem {
  /// Returns a new [FeedItem] instance.
  FeedItem({
    required this.appealId,
    required this.number,
    required this.type,
    required this.category,
    required this.department,
    required this.publicSummary,
    required this.result,
    required this.authorDisplay,
    required this.implementedAt,
    required this.discussionId,
  });

  int appealId;

  String number;

  AppealType type;

  CategoryRef? category;

  DepartmentRef? department;

  /// Что предложили
  String publicSummary;

  /// Что сделали — `public_result` обращения, а если он не задан — `result`
  String result;

  /// Имя автора при согласии, иначе подразделение
  String authorDisplay;

  DateTime implementedAt;

  int? discussionId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FeedItem &&
    other.appealId == appealId &&
    other.number == number &&
    other.type == type &&
    other.category == category &&
    other.department == department &&
    other.publicSummary == publicSummary &&
    other.result == result &&
    other.authorDisplay == authorDisplay &&
    other.implementedAt == implementedAt &&
    other.discussionId == discussionId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (appealId.hashCode) +
    (number.hashCode) +
    (type.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (publicSummary.hashCode) +
    (result.hashCode) +
    (authorDisplay.hashCode) +
    (implementedAt.hashCode) +
    (discussionId == null ? 0 : discussionId!.hashCode);

  @override
  String toString() => 'FeedItem[appealId=$appealId, number=$number, type=$type, category=$category, department=$department, publicSummary=$publicSummary, result=$result, authorDisplay=$authorDisplay, implementedAt=$implementedAt, discussionId=$discussionId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'appeal_id'] = this.appealId;
      json[r'number'] = this.number;
      json[r'type'] = this.type;
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
      json[r'public_summary'] = this.publicSummary;
      json[r'result'] = this.result;
      json[r'author_display'] = this.authorDisplay;
      json[r'implemented_at'] = this.implementedAt.toUtc().toIso8601String();
    if (this.discussionId != null) {
      json[r'discussion_id'] = this.discussionId;
    } else {
      json[r'discussion_id'] = null;
    }
    return json;
  }

  /// Returns a new [FeedItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FeedItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'appeal_id'), 'Required key "FeedItem[appeal_id]" is missing from JSON.');
        assert(json[r'appeal_id'] != null, 'Required key "FeedItem[appeal_id]" has a null value in JSON.');
        assert(json.containsKey(r'number'), 'Required key "FeedItem[number]" is missing from JSON.');
        assert(json[r'number'] != null, 'Required key "FeedItem[number]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "FeedItem[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "FeedItem[type]" has a null value in JSON.');
        assert(json.containsKey(r'category'), 'Required key "FeedItem[category]" is missing from JSON.');
        assert(json.containsKey(r'department'), 'Required key "FeedItem[department]" is missing from JSON.');
        assert(json.containsKey(r'public_summary'), 'Required key "FeedItem[public_summary]" is missing from JSON.');
        assert(json[r'public_summary'] != null, 'Required key "FeedItem[public_summary]" has a null value in JSON.');
        assert(json.containsKey(r'result'), 'Required key "FeedItem[result]" is missing from JSON.');
        assert(json[r'result'] != null, 'Required key "FeedItem[result]" has a null value in JSON.');
        assert(json.containsKey(r'author_display'), 'Required key "FeedItem[author_display]" is missing from JSON.');
        assert(json[r'author_display'] != null, 'Required key "FeedItem[author_display]" has a null value in JSON.');
        assert(json.containsKey(r'implemented_at'), 'Required key "FeedItem[implemented_at]" is missing from JSON.');
        assert(json[r'implemented_at'] != null, 'Required key "FeedItem[implemented_at]" has a null value in JSON.');
        assert(json.containsKey(r'discussion_id'), 'Required key "FeedItem[discussion_id]" is missing from JSON.');
        return true;
      }());

      return FeedItem(
        appealId: mapValueOfType<int>(json, r'appeal_id')!,
        number: mapValueOfType<String>(json, r'number')!,
        type: AppealType.fromJson(json[r'type'])!,
        category: CategoryRef.fromJson(json[r'category']),
        department: DepartmentRef.fromJson(json[r'department']),
        publicSummary: mapValueOfType<String>(json, r'public_summary')!,
        result: mapValueOfType<String>(json, r'result')!,
        authorDisplay: mapValueOfType<String>(json, r'author_display')!,
        implementedAt: mapDateTime(json, r'implemented_at', r'')!,
        discussionId: mapValueOfType<int>(json, r'discussion_id'),
      );
    }
    return null;
  }

  static List<FeedItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FeedItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FeedItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FeedItem> mapFromJson(dynamic json) {
    final map = <String, FeedItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FeedItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FeedItem-objects as value to a dart map
  static Map<String, List<FeedItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FeedItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FeedItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'appeal_id',
    'number',
    'type',
    'category',
    'department',
    'public_summary',
    'result',
    'author_display',
    'implemented_at',
    'discussion_id',
  };
}

