import 'package:flutter/material.dart';
import 'habitat_edit_page.dart';
import 'family_edit_page.dart';
import 'health_edit_page.dart';
import 'profession_edit_page.dart';
import 'mobility_edit_page.dart';
import 'social_edit_page.dart';
import 'identity_edit_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres utilisateur')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Identité'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Modifier identité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IdentityEditPage()),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Habitat'),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Modifier habitat'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HabitatEditPage()),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Famille'),
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Modifier famille'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FamilyEditPage()),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Santé'),
          ),
          ListTile(
            leading: const Icon(Icons.health_and_safety),
            title: const Text('Modifier santé'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HealthEditPage()),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Profession'),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Modifier profession'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfessionEditPage()),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Mobilité'),
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Modifier mobilité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MobilityEditPage()),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Social'),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Modifier social'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SocialEditPage()),
            ),
          ),
        ],
      ),
    );
  }
}
