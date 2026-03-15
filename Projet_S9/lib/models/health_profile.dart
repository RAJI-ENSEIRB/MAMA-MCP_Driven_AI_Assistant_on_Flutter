import 'package:hive/hive.dart';

part 'health_profile.g.dart';

@HiveType(typeId: 4)
class HealthProfile {
  @HiveField(0)
  final double weight; // en kg

  @HiveField(1)
  final double height; // en cm

  @HiveField(2)
  final String chronicDiseases; 

  @HiveField(3)
  final String allergies; 

  @HiveField(4)
  final String medications;

  HealthProfile({
    required this.weight,
    required this.height,
    required this.chronicDiseases,
    required this.allergies,
    required this.medications,
  });
}
