import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 1) // choisis un typeId libre chez toi
class UserProfile extends HiveObject {
  @HiveField(0)
  String? name;

  @HiveField(1)
  int? age;

  @HiveField(2)
  double? heightCm;

  @HiveField(3)
  double? weightKg;

  @HiveField(4)
  String? gender;

  UserProfile({this.name, this.age, this.heightCm, this.weightKg, this.gender});
}
