import 'package:hive/hive.dart';

part 'family_profile.g.dart';

@HiveType(typeId: 3)
class FamilyProfile {
  @HiveField(0)
  final String maritalStatus; // Célibataire, Marié, PACS, Divorcé

  @HiveField(1)
  final int numberOfChildren;

  @HiveField(2)
  final bool livesAlone;

  @HiveField(3)
  final bool hasPets;

  FamilyProfile({
    required this.maritalStatus,
    required this.numberOfChildren,
    required this.livesAlone,
    required this.hasPets,
  });
}
