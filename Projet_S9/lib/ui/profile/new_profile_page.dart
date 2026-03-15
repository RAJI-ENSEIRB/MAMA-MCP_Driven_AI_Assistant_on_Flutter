// lib/ui/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_state.dart';
import '../../models/identity_profile.dart';
import '../settings/identity_edit_page.dart';
import '../settings/habitat_edit_page.dart';
import '../settings/family_edit_page.dart';
import '../settings/health_edit_page.dart';
import '../settings/profession_edit_page.dart';
import '../settings/mobility_edit_page.dart';
import '../settings/social_edit_page.dart';
import '../settings/theme_settings_page.dart';

class NewProfileTab extends StatefulWidget {
  const NewProfileTab({super.key});

  @override
  State<NewProfileTab> createState() => _NewProfileTabState();
}

class _NewProfileTabState extends State<NewProfileTab> {
  // Champs
  final _nameController = TextEditingController();

  // Valeurs sauvegardées
  String? _savedFirstName;

  bool _loading = true;

  late Box<IdentityProfile> _identityBox;

  @override
  void initState() {
    super.initState();
    _identityBox = Hive.box<IdentityProfile>('identity_box');
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final profile = _identityBox.get('profile');

    if (profile != null) {
      _nameController.text = profile.firstName;

      _savedFirstName = profile.firstName;

      // plus de mode édition ici; on affiche uniquement le header
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          // Accès aux paramètres (édition) directement depuis le profil
          _buildSettingsShortcuts(context),
          const SizedBox(height: 16),
          _buildThemeBox(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = Provider.of<AuthState>(context);

    final bool isLoggedIn = auth.isLoggedIn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.primary.withOpacity(0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texte à gauche
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _savedFirstName != null && _savedFirstName!.isNotEmpty
                      ? "Bonjour, $_savedFirstName"
                      : "Mon profil",
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Bienvenue sur votre profil",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),

          // Icône connexion / déconnexion
          IconButton(
            tooltip: isLoggedIn ? "Se déconnecter" : "Se connecter avec Google",
            icon: Icon(
              isLoggedIn ? Icons.logout : Icons.login,
              color: cs.primary,
              size: 28,
            ),
            onPressed: () async {
              if (isLoggedIn) {
                await auth.logout();
              } else {
                await auth.login();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsShortcuts(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres utilisateur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            Text(
              'Modifier vos informations par section',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              context,
              Icons.person,
              'Identité',
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IdentityEditPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              Icons.home,
              'Habitat',
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HabitatEditPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              Icons.family_restroom,
              'Famille',
              () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FamilyEditPage())),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              Icons.health_and_safety,
              'Santé',
              () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HealthEditPage())),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              Icons.work,
              'Profession',
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfessionEditPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              Icons.directions_bus,
              'Mobilité',
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MobilityEditPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              Icons.group,
              'Social',
              () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SocialEditPage())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeBox(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apparence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            Text(
              'Couleurs et thème de l’interface',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              context,
              Icons.palette,
              'Thème',
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.15),
                    cs.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: cs.onSurface.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
