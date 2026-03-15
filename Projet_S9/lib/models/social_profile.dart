import 'package:hive/hive.dart';

part 'social_profile.g.dart';

@HiveType(typeId: 7)
class SocialProfile {
  @HiveField(0)
  final String activities; 

  @HiveField(1)
  final String stressLevel; 

  @HiveField(2)
  final String sleepQuality; 

  @HiveField(3)
  final String consumptions; 

  SocialProfile({
    required this.activities,
    required this.stressLevel,
    required this.sleepQuality,
    required this.consumptions,
  });
}
