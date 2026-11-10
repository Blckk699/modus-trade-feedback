//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AppealPage {
  /// Returns a new [AppealPage] instance.
  AppealPage({
    this.items = const [],
    required this.total,
    required this.page,
    required this.pageSize,
  });

  List<AppealListItem> items;

  int total;

  int page;

  int pageSize;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AppealPage &&
    _deepEquality.equals(other.items, items) &&
    other.total == total &&
    other.page == page &&
    other.pageSize == pageSize;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (items.hashCode) +
    (total.hashCode) +
    (page.hashCode) +
    (pageSize.hashCode);

  @override
  String toString() => 'AppealPage[items=$items, total=$total, page=$page, pageSize=$pageSize]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'items'] = this.items;
      json[r'total'] = this.total;
      json[r'page'] = this.page;
      json[r'page_size'] = this.pageSize;
    return json;
  }

  /// Returns a new [AppealPage] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppealPage? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'items'), 'Required key "AppealPage[items]" is missing from JSON.');
        assert(json[r'items'] != null, 'Required key "AppealPage[items]" has a null value in JSON.');
        assert(json.containsKey(r'total'), 'Required key "AppealPage[total]" is missing from JSON.');
        assert(json[r'total'] != null, 'Required key "AppealPage[total]" has a null value in JSON.');
        assert(json.containsKey(r'page'), 'Required key "AppealPage[page]" is missing from JSON.');
        assert(json[r'page'] != null, 'Required key "AppealPage[page]" has a null value in JSON.');
        assert(json.containsKey(r'page_size'), 'Required key "AppealPage[page_size]" is missing from JSON.');
        assert(json[r'page_size'] != null, 'Required key "AppealPage[page_size]" has a null value in JSON.');
        return true;
      }());

      return AppealPage(
        items: AppealListItem.listFromJson(json[r'items']),
        total: mapValueOfType<int>(json, r'total')!,
        page: mapValueOfType<int>(json, r'page')!,
        pageSize: mapValueOfType<int>(json, r'page_size')!,
      );
    }
    return null;
  }

  static List<AppealPage> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AppealPage>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppealPage.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppealPage> mapFromJson(dynamic json) {
    final map = <String, AppealPage>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppealPage.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppealPage-objects as value to a dart map
  static Map<String, List<AppealPage>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AppealPage>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppealPage.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'items',
    'total',
    'page',
    'page_size',
  };
}

