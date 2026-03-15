import 'package:hive/hive.dart';

part 'habitat_profile.g.dart';

@HiveType(typeId: 2)
class HabitatProfile {
  @HiveField(0)
  final String type; // Maison, Appartement, Studio...

  @HiveField(1)
  final String city;

  @HiveField(2)
  final int floor; // 0 pour RDC, 1 pour 1er étage...

  HabitatProfile({
    required this.type,
    required this.city,
    required this.floor,
  });
}
