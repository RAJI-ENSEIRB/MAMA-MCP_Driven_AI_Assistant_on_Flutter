import 'package:logging/logging.dart';
import 'package:hive/hive.dart';

final log = Logger('SleepRepository');

abstract class SleepRepository {
  Future<void> init();
  Future<List<Map<String, dynamic>>> getSleep(String date);
  Future<Map<String, dynamic>> addSleep(String date, String wakingupTime, String bedTime, int sleepQuality);
  Map<String, dynamic>? getSleepById(int id);
  bool deleteSleepById(int id);
  bool updateSleepById(int id, Map<String, dynamic> updates);
}

class InMemorySleepRepository implements SleepRepository {
  static const String _boxName = 'sleep';
  late Box _box;
  int _nextId = 1;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);

    if (_box.isNotEmpty) {
      final ids = _box.values.map((d) => (d['id'] ?? 0) as int);
      _nextId = ids.reduce((a, b) => a > b ? a : b) + 1;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSleep(String date) async {
    final List<Map<String, dynamic>> sleeps = [];
   for (var sleep in _box.values) {
      if (sleep['date'] == date) {
      //  var meal = sleep['meal'] ?? 'unknown';
      //  if (!['breakfast', 'lunch', 'dinner', 'snack'].contains(meal)) {
      //    meal = 'unknown';
      //  }
       sleeps.add({
          'id': sleep['id'],
          "wakeupTime": sleep['wakingupTime'],
          "date": sleep['date'],
          "bedTime": sleep['bedTime'],
          "quality": sleep['sleepQuality'],
        });
      }
    }
    return sleeps;
  }

  @override
  Future<Map<String, dynamic>> addSleep(String date, String wakingupTime, String bedTime, int sleepQuality) async {
    final newSleep = {
      'id': _nextId++,
      "wakeupTime": wakingupTime,
      "date": date,
      "bedTime": bedTime,
      "quality": sleepQuality,
    };
    await _box.put(newSleep['id'], newSleep);
    return newSleep;
  }

  @override
  Map<String, dynamic>? getSleepById(int id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  @override
  bool deleteSleepById(int id) {
    if (!_box.containsKey(id)) return false;
    _box.delete(id);
    return true;
  }

  @override
  bool updateSleepById(int id, Map<String, dynamic> updates) {
    Map<String, dynamic>? sleep = Map<String, dynamic>.from(_box.get(id) ?? {});
    if (sleep.isEmpty) return false;

    final updatedSleep = {...sleep, ...updates};
    _box.put(id, updatedSleep);
    return true;
  }

  Future<void> resetAllSleep() async {
    await _box.clear();
    _nextId = 1;
  }
}