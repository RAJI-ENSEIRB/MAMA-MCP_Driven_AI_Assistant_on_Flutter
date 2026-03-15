import 'package:logging/logging.dart';
import 'package:hive/hive.dart';

final log = Logger('DishesRepository');

abstract class DishesRepository {
  Future<void> init();
  Future<List<Map<String, dynamic>>> getDishes(String date);
  Future<Map<String, dynamic>> addDish(String name, String date, String meal, String quantity);
  Map<String, dynamic>? getDishById(int id);
  bool deleteDishById(int id);
  bool updateDishById(int id, Map<String, dynamic> updates);
}

class InMemoryDishesRepository implements DishesRepository {
  static const String _boxName = 'S9_dishes';
  late Box _box;
  int _nextId = 1;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);

    if (_box.isNotEmpty) {
      final ids = _box.values
          .whereType<Map>()
          .map((d) => (d['id'] ?? 0) as int);
      if (ids.isNotEmpty) {
        _nextId = ids.reduce((a, b) => a > b ? a : b) + 1;
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDishes(String date) async {
    final List<Map<String, dynamic>> dishes = [];

    for (var dish in _box.values) {
      if (dish is! Map) continue;
      if (dish['date'] == date) {
        var meal = dish['meal'] ?? 'unknown';
        if (!['breakfast', 'lunch', 'dinner', 'snack'].contains(meal)) {
          meal = 'unknown';
        }

        dishes.add({
          'id': dish['id'],
          'name': dish['name'],
          'date': dish['date'],
          'meal': meal,
          'quantity': dish['quantity'] ?? '1',
        });
      }
    }
    return dishes;
  }

  @override
  Future<Map<String, dynamic>> addDish(String name, String date, String meal, String quantity) async {
    final existing = _box.values.whereType<Map>().cast<Map>().firstWhere(
      (dish) {
        final dishName = dish['name']?.toString() ?? '';
        final dishMeal = dish['meal']?.toString() ?? '';
        final dishDate = dish['date']?.toString() ?? '';
        return dishName.toLowerCase() == name.toLowerCase() && 
          dishMeal == meal && 
          isSameDate(dishDate, date);
      },
      orElse: () => {},
    );
    if (existing.isNotEmpty) {
      throw Exception("Dish '$name' already exists for meal '$meal' on date '$date'");
    }

    final newDish = {
      'id': _nextId++,
      "name": name,
      "meal": meal,
      "date": date,
      "quantity": quantity,
    };
    _box.put(newDish['id'], newDish);
    return newDish;
  }

  bool isSameDate(String date1, String date2) {
    try {
      final d1 = DateTime.parse(date1);
      final d2 = DateTime.parse(date2);
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
    } catch (e) {
      // Fallback to string comparison
      return date1.split(' ').first == date2.split(' ').first;
    }
  }

  @override
  Map<String, dynamic>? getDishById(int id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  @override
  bool deleteDishById(int id) {
    if (!_box.containsKey(id)) return false;
    _box.delete(id);
    return true;
  }

  @override
  bool updateDishById(int id, Map<String, dynamic> updates) {
    final raw = _box.get(id);
    if (raw == null || raw is! Map) return false;
    Map<String, dynamic> dish = Map<String, dynamic>.from(raw);

    final safeUpdates = Map<String, dynamic>.from(updates);
    safeUpdates.remove('id');

    final updatedDish = {...dish, ...safeUpdates};
    if (updates.containsKey('name') || updates.containsKey('meal') || updates.containsKey('date')) {
      final proposedName = updatedDish['name']?.toString() ?? '';
      final proposedMeal = updatedDish['meal']?.toString() ?? '';
      final proposedDate = updatedDish['date']?.toString() ?? '';

      final existing = _box.values.whereType<Map>().cast<Map>().firstWhere(
        (d) {
          if ((d['id'] ?? 0) == id) return false; // Skip self
          final dName = d['name']?.toString() ?? '';
          final dMeal = d['meal']?.toString() ?? '';
          final dDate = d['date']?.toString() ?? '';
          return dName.toLowerCase() == proposedName.toLowerCase() && 
            dMeal == proposedMeal && 
            dDate.split(' ').first == proposedDate.split(' ').first;
        },
        orElse: () => {},
      );

      if (existing.isNotEmpty) {
        return false;
      }
    }

    _box.put(id, updatedDish);
    return true;
  }

  Future<void> resetAllDishes() async {
    await _box.clear();
    _nextId = 1;
  }
}