import 'package:hive/hive.dart';

part 'profession_profile.g.dart';

@HiveType(typeId: 5)
class ProfessionProfile {
  @HiveField(0)
  final String job;

  @HiveField(1)
  final String timeStatus; // Temps plein, Temps partiel, Indépendant

  @HiveField(2)
  final String workLocation; // Bureau, Télétravail, Hybride

  @HiveField(3)
  final int commutingDistance; // en km

  ProfessionProfile({
    required this.job,
    required this.timeStatus,
    required this.workLocation,
    required this.commutingDistance,
  });
}
