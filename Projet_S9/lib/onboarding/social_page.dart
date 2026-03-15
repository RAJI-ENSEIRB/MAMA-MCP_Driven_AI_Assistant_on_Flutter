import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/social_profile.dart';

class SocialPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const SocialPage({super.key, required this.onComplete, required this.onSkip});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final _formKey = GlobalKey<FormState>();
  final _activitiesController = TextEditingController();
  String _stressLevel = 'Modéré';
  String _sleepQuality = 'Moyenne';
  final _consumptionsController = TextEditingController();

  @override
  void dispose() {
    _activitiesController.dispose();
    _consumptionsController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<SocialProfile>('social_box');
      final profile = SocialProfile(
        activities: _activitiesController.text.trim(),
        stressLevel: _stressLevel,
        sleepQuality: _sleepQuality,
        consumptions: _consumptionsController.text.trim(),
      );
      await box.put('profile', profile);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social & Bien-être'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Catégorie 7 / 7',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vie sociale et bien-être',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _activitiesController,
                decoration: const InputDecoration(
                  labelText: 'Activités et loisirs (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _stressLevel,
                decoration: const InputDecoration(
                  labelText: 'Niveau de stress',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Faible', child: Text('Faible')),
                  DropdownMenuItem(value: 'Modéré', child: Text('Modéré')),
                  DropdownMenuItem(value: 'Élevé', child: Text('Élevé')),
                ],
                onChanged: (value) {
                  setState(() {
                    _stressLevel = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _sleepQuality,
                decoration: const InputDecoration(
                  labelText: 'Qualité du sommeil',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Mauvaise', child: Text('Mauvaise')),
                  DropdownMenuItem(value: 'Moyenne', child: Text('Moyenne')),
                  DropdownMenuItem(value: 'Bonne', child: Text('Bonne')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sleepQuality = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _consumptionsController,
                decoration: const InputDecoration(
                  labelText: 'Consommations (alcool, tabac, etc) (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveAndContinue,
                child: const Text('Terminer'),
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
