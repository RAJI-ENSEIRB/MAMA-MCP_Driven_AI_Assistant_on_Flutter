import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/profession_profile.dart';

class ProfessionPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const ProfessionPage({super.key, required this.onComplete, required this.onSkip});

  @override
  State<ProfessionPage> createState() => _ProfessionPageState();
}

class _ProfessionPageState extends State<ProfessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _jobController = TextEditingController();
  String _timeStatus = 'Temps plein';
  String _workLocation = 'Bureau';
  final _distanceController = TextEditingController();

  @override
  void dispose() {
    _jobController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<ProfessionProfile>('profession_box');
      final profile = ProfessionProfile(
        job: _jobController.text.trim(),
        timeStatus: _timeStatus,
        workLocation: _workLocation,
        commutingDistance: int.parse(_distanceController.text),
      );
      await box.put('profile', profile);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profession'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Catégorie 5 / 7',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vie professionnelle',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _jobController,
                decoration: const InputDecoration(
                  labelText: 'Métier',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer votre métier';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _timeStatus,
                decoration: const InputDecoration(
                  labelText: 'Temps de travail',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Temps plein', child: Text('Temps plein')),
                  DropdownMenuItem(value: 'Temps partiel', child: Text('Temps partiel')),
                  DropdownMenuItem(value: 'Indépendant', child: Text('Indépendant')),
                ],
                onChanged: (value) {
                  setState(() {
                    _timeStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _workLocation,
                decoration: const InputDecoration(
                  labelText: 'Lieu de travail',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Bureau', child: Text('Bureau')),
                  DropdownMenuItem(value: 'Télétravail', child: Text('Télétravail')),
                  DropdownMenuItem(value: 'Hybride', child: Text('Hybride')),
                ],
                onChanged: (value) {
                  setState(() {
                    _workLocation = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance trajet (km)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer la distance';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveAndContinue,
                child: const Text('Suivant'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onSkip,
                child: const Text('Passer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
