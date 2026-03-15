import 'package:hive/hive.dart';

part 'mobility_profile.g.dart';

@HiveType(typeId: 6)
class MobilityProfile {
  @HiveField(0)
  final bool hasDrivingLicense;

  @HiveField(1)
  final String primaryTransport; // Voiture, Transports en commun, Vélo, A pied

  @HiveField(2)
  final List<String> otherTransports; 

  MobilityProfile({
    required this.hasDrivingLicense,
    required this.primaryTransport,
    required this.otherTransports,
  });
}
