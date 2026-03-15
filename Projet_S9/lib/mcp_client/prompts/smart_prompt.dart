import 'dart:convert';

String getSmartSystemPrompt(String dateStr, Map<String, dynamic> userProfile) {
  // Format user profile information
  String profileInfo = _formatUserProfile(userProfile);

  // Debug: print profile to see what the AI receives
  print('=== PROFILE INFO FOR AI ===');
  print(profileInfo);
  print('=== END PROFILE INFO ===');

  return """
  Tu es un assistant personnel intelligent et proactif.

  DATE ACTUELLE : $dateStr

  **PROFIL UTILISATEUR** :
  $profileInfo

  **RÈGLES IMPORTANTES** :

  1. 🎯 **Personnalisation** :
     - Utilise les informations du profil pour personnaliser tes réponses
     - Adresse l'utilisateur par son prénom dans les salutations
     - Tiens compte de sa santé, ses habitudes, son lieu de vie, etc.

  2. 🔧 **Outils contextuels** :
     - Tu as accès à des outils pour obtenir des informations contextuelles (météo, localisation, sommeil, menu)
     - Utilise ces outils UNIQUEMENT quand c'est pertinent pour la question posée
     - Ne les appelle pas systématiquement si ce n'est pas nécessaire

  3. 💬 **Communication naturelle** :
     - Réponds de manière naturelle et personnalisée
     - Ne mentionne pas explicitement que tu as appelé des outils
     - Intègre les informations du profil et du contexte de façon fluide

  **EXEMPLES** :

  Question : "Propose-moi une activité pour ce soir"
  → Utilise get_current_location et get_weather pour connaître les conditions
  → Utilise get_sleep si disponible pour savoir s'il est fatigué
  → Propose une activité adaptée à sa localisation, la météo, et son état de forme

  Question : "Bonjour"
  → Réponds : "Bonjour [prénom] ! Comment puis-je t'aider aujourd'hui ?"
  → Pas besoin d'appeler des outils pour une simple salutation

  Question : "Quel temps fait-il ?"
  → Utilise get_current_location et get_weather
  → Réponds avec les informations météo actuelles

  **RÈGLES TECHNIQUES** :

  - Tu peux appeler plusieurs outils si nécessaire
  - Si un outil échoue, continue avec les données disponibles
  - Sois proactif mais pas intrusif
  - Utilise les tools de manière intelligente selon le contexte
  """;
}

String _formatUserProfile(Map<String, dynamic> profile) {
  if (profile.isEmpty) {
    return "Aucune information de profil disponible.";
  }

  final buffer = StringBuffer();

  // Parse and format each profile section
  profile.forEach((key, value) {
    if (value == null || value.toString().isEmpty) return;

    try {
      // Try to parse JSON if it's a string
      dynamic data = value;
      if (value is String) {
        try {
          data = jsonDecode(value);
        } catch (e) {
          data = value;
        }
      }

      switch (key) {
        case 'get_identity_profile':
          if (data is Map) {
            buffer.writeln('📋 **Identité** :');
            if (data['firstName'] != null) buffer.writeln('  - Prénom : ${data['firstName']}');
            if (data['lastName'] != null) buffer.writeln('  - Nom : ${data['lastName']}');
            if (data['gender'] != null) buffer.writeln('  - Genre : ${data['gender']}');
            if (data['age'] != null) buffer.writeln('  - Âge : ${data['age']} ans');
            buffer.writeln();
          }
          break;

        case 'get_habitat_profile':
          if (data is Map) {
            buffer.writeln('🏠 **Habitat** :');
            if (data['type'] != null) buffer.writeln('  - Type : ${data['type']}');
            if (data['city'] != null) buffer.writeln('  - Ville : ${data['city']}');
            if (data['floor'] != null) buffer.writeln('  - Étage : ${data['floor']}');
            buffer.writeln();
          }
          break;

        case 'get_family_profile':
          if (data is Map) {
            buffer.writeln('👨‍👩‍👧‍👦 **Famille** :');
            if (data['maritalStatus'] != null) buffer.writeln('  - Statut marital : ${data['maritalStatus']}');
            if (data['numberOfChildren'] != null) buffer.writeln('  - Enfants : ${data['numberOfChildren']}');
            if (data['livesAlone'] != null) buffer.writeln('  - Vit seul : ${data['livesAlone'] ? 'Oui' : 'Non'}');
            if (data['hasPets'] != null) buffer.writeln('  - Animaux : ${data['hasPets'] ? 'Oui' : 'Non'}');
            buffer.writeln();
          }
          break;

        case 'get_health_profile':
          if (data is Map) {
            buffer.writeln('🏥 **Santé** :');
            if (data['weight'] != null) buffer.writeln('  - Poids : ${data['weight']} kg');
            if (data['height'] != null) buffer.writeln('  - Taille : ${data['height']} cm');
            if (data['chronicDiseases'] != null && data['chronicDiseases'].isNotEmpty) {
              buffer.writeln('  - Maladies chroniques : ${data['chronicDiseases']}');
            }
            if (data['allergies'] != null && data['allergies'].isNotEmpty) {
              buffer.writeln('  - Allergies : ${data['allergies']}');
            }
            if (data['medications'] != null && data['medications'].isNotEmpty) {
              buffer.writeln('  - Médicaments : ${data['medications']}');
            }
            buffer.writeln();
          }
          break;

        case 'get_profession_profile':
          if (data is Map) {
            buffer.writeln('💼 **Profession** :');
            if (data['job'] != null) buffer.writeln('  - Métier : ${data['job']}');
            if (data['timeStatus'] != null) buffer.writeln('  - Temps de travail : ${data['timeStatus']}');
            if (data['workLocation'] != null) buffer.writeln('  - Lieu de travail : ${data['workLocation']}');
            if (data['commutingDistance'] != null) buffer.writeln('  - Distance domicile-travail : ${data['commutingDistance']} km');
            buffer.writeln();
          }
          break;

        case 'get_mobility_profile':
          if (data is Map) {
            buffer.writeln('🚗 **Mobilité** :');
            if (data['hasDrivingLicense'] != null) buffer.writeln('  - Permis de conduire : ${data['hasDrivingLicense'] ? 'Oui' : 'Non'}');
            if (data['primaryTransport'] != null) buffer.writeln('  - Transport principal : ${data['primaryTransport']}');
            if (data['otherTransports'] != null && data['otherTransports'].isNotEmpty) {
              buffer.writeln('  - Autres transports : ${data['otherTransports']}');
            }
            buffer.writeln();
          }
          break;

        case 'get_social_profile':
          if (data is Map) {
            buffer.writeln('🎭 **Social** :');
            if (data['activities'] != null && data['activities'].isNotEmpty) {
              buffer.writeln('  - Activités : ${data['activities']}');
            }
            if (data['stressLevel'] != null) buffer.writeln('  - Niveau de stress : ${data['stressLevel']}/5');
            if (data['sleepQuality'] != null) buffer.writeln('  - Qualité de sommeil : ${data['sleepQuality']}/5');
            if (data['consumptions'] != null && data['consumptions'].isNotEmpty) {
              buffer.writeln('  - Consommations : ${data['consumptions']}');
            }
            buffer.writeln();
          }
          break;
      }
    } catch (e) {
      // Ignore parsing errors
    }
  });

  return buffer.isEmpty ? "Aucune information de profil disponible." : buffer.toString();
}