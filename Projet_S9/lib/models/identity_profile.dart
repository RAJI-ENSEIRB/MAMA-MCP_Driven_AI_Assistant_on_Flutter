import 'package:hive/hive.dart';

part 'identity_profile.g.dart';

@HiveType(typeId: 0)
class IdentityProfile extends HiveObject {
  @HiveField(0)
  String firstName;

  @HiveField(1)
  String lastName;

  @HiveField(2)
  String gender; // "Homme", "Femme", "Autre"

  @HiveField(3)
  DateTime birthDate;

  IdentityProfile({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthDate,
  });

  // Utile pour afficher l'âge
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
