import 'package:mcp_dart/mcp_dart.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/identity_profile.dart';
import '../../models/habitat_profile.dart';
import '../../models/family_profile.dart';
import '../../models/health_profile.dart';
import '../../models/profession_profile.dart';
import '../../models/mobility_profile.dart';
import '../../models/social_profile.dart';

class ProfileTools {
  void register(McpServer server) {
    // Tool 1: Get Identity Profile
    server.registerTool(
      'get_identity_profile',
      description: 'Récupère le profil d\'identité de l\'utilisateur : prénom, nom, genre, date de naissance et âge calculé.',
      callback: (args, extra) async {
        try {
          final box = await Hive.openBox<IdentityProfile>('identity_box');
          final profile = box.get('profile');

          if (profile == null) {
            return CallToolResult(
              content: [TextContent(text: 'Aucun profil d\'identité trouvé')],
            );
          }

          final result = {
            'firstName': profile.firstName,
            'lastName': profile.lastName,
            'gender': profile.gender,
            'birthDate': profile.birthDate.toIso8601String(),
            'age': profile.age,
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_identity_profile: $e')],
            isError: true,
          );
        }
      },
    );

    // Tool 2: Get Habitat Profile
    server.registerTool(
      'get_habitat_profile',
      description: 'Récupère le profil d\'habitat de l\'utilisateur : type de logement, ville, étage.',
      callback: (args, extra) async {
        try {
          final box = await Hive.openBox<HabitatProfile>('habitat_box');
          final profile = box.get('profile');

          if (profile == null) {
            return CallToolResult(
              content: [TextContent(text: 'Aucun profil d\'habitat trouvé')],
            );
          }

          final result = {
            'type': profile.type,
            'city': profile.city,
            'floor': profile.floor,
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_habitat_profile: $e')],
            isError: true,
          );
        }
      },
    );

    // Tool 3: Get Family Profile
    server.registerTool(
      'get_family_profile',
      description: 'Récupère le profil familial de l\'utilisateur : statut marital, nombre d\'enfants, vit seul, a des animaux.',
      callback: (args, extra) async {
        try {
          final box = await Hive.openBox<FamilyProfile>('family_box');
          final profile = box.get('profile');

          if (profile == null) {
            return CallToolResult(
              content: [TextContent(text: 'Aucun profil familial trouvé')],
            );
          }

          final result = {
            'maritalStatus': profile.maritalStatus,
            'numberOfChildren': profile.numberOfChildren,
            'livesAlone': profile.livesAlone,
            'hasPets': profile.hasPets,
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_family_profile: $e')],
            isError: true,
          );
        }
      },
    );

    // Tool 4: Get Health Profile
    server.registerTool(
      'get_health_profile',
      description: 'Récupère le profil de santé de l\'utilisateur : poids, taille, maladies chroniques, allergies, médicaments.',
      callback: (args, extra) async {
        try {
          final box = await Hive.openBox<HealthProfile>('health_box');
          final profile = box.get('profile');

          if (profile == null) {
            return CallToolResult(
              content: [TextContent(text: 'Aucun profil de santé trouvé')],
            );
          }

          final result = {
            'weight': profile.weight,
            'height': profile.height,
            'chronicDiseases': profile.chronicDiseases,
            'allergies': profile.allergies,
            'medications': profile.medications,
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_health_profile: $e')],
            isError: true,
          );
        }
      },
    );

    // Tool 5: Get Profession Profile
    server.registerTool(
      'get_profession_profile',
      description: 'Récupère le profil professionnel de l\'utilisateur : métier, statut temps de travail, lieu de travail, distance de trajet.',
      callback: (args, extra) async {
        try {
          final box = await Hive.openBox<ProfessionProfile>('profession_box');
          final profile = box.get('profile');

          if (profile == null) {
            return CallToolResult(
              content: [TextContent(text: 'Aucun profil professionnel trouvé')],
            );
          }

          final result = {
            'job': profile.job,
            'timeStatus': profile.timeStatus,
            'workLocation': profile.workLocation,
            'commutingDistance': profile.commutingDistance,
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_profession_profile: $e')],
            isError: true,
          );
        }
      },
    );

    // Tool 6: Get Mobility Profile
    server.registerTool(
      'get_mobility_profile',
      description: 'Récupère le profil de mobilité de l\'utilisateur : possession de permis de conduire, transport principal, autres transports.',
      callback: (args, extra) async {
        try {
          final box = await Hive.openBox<MobilityProfile>('mobility_box');
          final profile = box.get('profile');

          if (profile == null) {
            return CallToolResult(
              content: [TextContent(text: 'Aucun profil de mobilité trouvé')],
            );
          }

          final result = {
            'hasDrivingLicense': profile.hasDrivingLicense,
            'primaryTransport': profile.primaryTransport,
            'otherTransports': profile.otherTransports,
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_mobility_profile: $e')],
            isError: true,
          );
        }
      },
    );

    // Tool 7: Get Social Profile
    server.registerTool(
      'get_social_profile',
      description: 'Récupère le profil social de l\'utilisateur : activités pratiquées, niveau de stress, qualité de sommeil, consommations.',
      callback: (args, extra) async {
        try {
          final box = await Hive.openBox<SocialProfile>('social_box');
          final profile = box.get('profile');

          if (profile == null) {
            return CallToolResult(
              content: [TextContent(text: 'Aucun profil social trouvé')],
            );
          }

          final result = {
            'activities': profile.activities,
            'stressLevel': profile.stressLevel,
            'sleepQuality': profile.sleepQuality,
            'consumptions': profile.consumptions,
          };

          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
          );
        } catch (e) {
          return CallToolResult(
            content: [TextContent(text: 'Erreur get_social_profile: $e')],
            isError: true,
          );
        }
      },
    );
  }
}
