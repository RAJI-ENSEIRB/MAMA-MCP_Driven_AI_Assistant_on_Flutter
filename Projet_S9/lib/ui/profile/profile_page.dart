// lib/ui/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_state.dart';
import 'user_profile.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();

  // Champs
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Valeurs sauvegardées
  String? _gender;
  String? _savedName;
  int? _savedAge;
  double? _savedHeight;
  double? _savedWeight;
  String? _savedGender;

  bool _isEditing = true;
  bool _loading = true;

  late Box<UserProfile> _profileBox;

  @override
  void initState() {
    super.initState();
    _profileBox = Hive.box<UserProfile>('user_profile');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = _profileBox.get('current');

    if (profile != null) {
      _nameController.text = profile.name ?? "";
      _ageController.text = profile.age?.toString() ?? "";
      _heightController.text = profile.heightCm?.toString() ?? "";
      _weightController.text = profile.weightKg?.toString() ?? "";
      _gender = profile.gender;

      _savedName = profile.name;
      _savedAge = profile.age;
      _savedHeight = profile.heightCm;
      _savedWeight = profile.weightKg;
      _savedGender = profile.gender;

      _isEditing = false;
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double? _parseDouble(String text) =>
      text.trim().isEmpty ? null : double.tryParse(text.replaceAll(",", "."));

  int? _parseInt(String text) =>
      text.trim().isEmpty ? null : int.tryParse(text);

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      name: _nameController.text.trim(),
      age: _parseInt(_ageController.text),
      heightCm: _parseDouble(_heightController.text),
      weightKg: _parseDouble(_weightController.text),
      gender: _gender,
    );

    await _profileBox.put('current', profile);

    setState(() {
      _savedName = profile.name;
      _savedAge = profile.age;
      _savedHeight = profile.heightCm;
      _savedWeight = profile.weightKg;
      _savedGender = profile.gender;
      _isEditing = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profil mis à jour")));
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
          _isEditing ? _buildEditForm(context) : _buildProfileView(context),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                  _savedName != null && _savedName!.isNotEmpty
                      ? "Bonjour, $_savedName"
                      : "Mon profil",
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEditing
                      ? "Complète tes informations personnelles."
                      : "Informations enregistrées.",
                  style: TextStyle(
                    color: cs.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Icône connexion / déconnexion
          IconButton(
            tooltip: isLoggedIn ? "Se déconnecter" : "Se connecter avec Google",
            icon: Icon(
              isLoggedIn ? Icons.logout : Icons.login,
              color: cs.onPrimaryContainer,
              size: 30,
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

  // -----------------------------------------------------------
  // MODE LECTURE
  // -----------------------------------------------------------
  Widget _buildProfileView(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info("Prénom", _savedName),
            _info("Âge", _savedAge != null ? "$_savedAge ans" : null),
            _info("Taille", _savedHeight != null ? "${_savedHeight} cm" : null),
            _info("Poids", _savedWeight != null ? "${_savedWeight} kg" : null),
            _info("Genre", _savedGender),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.edit),
                label: const Text("Modifier"),
                onPressed: () => setState(() => _isEditing = true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // MODE ÉDITION
  // -----------------------------------------------------------
  Widget _buildEditForm(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_nameController, "Prénom", Icons.person),
              _field(
                _ageController,
                "Âge",
                Icons.cake_outlined,
                isNumber: true,
              ),
              _field(
                _heightController,
                "Taille (cm)",
                Icons.height,
                isNumber: true,
              ),
              _field(
                _weightController,
                "Poids (kg)",
                Icons.monitor_weight,
                isNumber: true,
              ),

              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Genre",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _chip("F", "Femme"),
                  _chip("M", "Homme"),
                  _chip("Autre", "Autre"),
                ],
              ),

              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Enregistrer"),
                onPressed: _saveProfile,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // WIDGETS UTILES
  // -----------------------------------------------------------
  Widget _chip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _gender == value,
      onSelected: (b) => setState(() => _gender = b ? value : null),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          if (label != "Prénom" && (v == null || v.trim().isEmpty)) {
            return "Champ requis";
          }
          return null;
        },
      ),
    );
  }

  Widget _info(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            "$label : ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
