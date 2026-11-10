//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BitrixTask {
  /// Returns a new [BitrixTask] instance.
  BitrixTask({
    required this.taskId,
    required this.url,
    required this.createdAt,
  });

  String taskId;

  String url;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BitrixTask &&
    other.taskId == taskId &&
    other.url == url &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (taskId.hashCode) +
    (url.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'BitrixTask[taskId=$taskId, url=$url, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'task_id'] = this.taskId;
      json[r'url'] = this.url;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [BitrixTask] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BitrixTask? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'task_id'), 'Required key "BitrixTask[task_id]" is missing from JSON.');
        assert(json[r'task_id'] != null, 'Required key "BitrixTask[task_id]" has a null value in JSON.');
        assert(json.containsKey(r'url'), 'Required key "BitrixTask[url]" is missing from JSON.');
        assert(json[r'url'] != null, 'Required key "BitrixTask[url]" has a null value in JSON.');
        assert(json.containsKey(r'created_at'), 'Required key "BitrixTask[created_at]" is missing from JSON.');
        assert(json[r'created_at'] != null, 'Required key "BitrixTask[created_at]" has a null value in JSON.');
        return true;
      }());

      return BitrixTask(
        taskId: mapValueOfType<String>(json, r'task_id')!,
        url: mapValueOfType<String>(json, r'url')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<BitrixTask> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BitrixTask>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BitrixTask.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BitrixTask> mapFromJson(dynamic json) {
    final map = <String, BitrixTask>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BitrixTask.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BitrixTask-objects as value to a dart map
  static Map<String, List<BitrixTask>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BitrixTask>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BitrixTask.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'task_id',
    'url',
    'created_at',
  };
}

