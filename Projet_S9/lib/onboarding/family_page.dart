import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/family_profile.dart';

class FamilyPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const FamilyPage({super.key, required this.onComplete, required this.onSkip});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  final _formKey = GlobalKey<FormState>();
  String _maritalStatus = 'Célibataire';
  int _numberOfChildren = 0;
  bool _livesAlone = true;
  bool _hasPets = false;

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<FamilyProfile>('family_box');
      final profile = FamilyProfile(
        maritalStatus: _maritalStatus,
        numberOfChildren: _numberOfChildren,
        livesAlone: _livesAlone,
        hasPets: _hasPets,
      );
      await box.put('profile', profile);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Famille'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Catégorie 3 / 7',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Situation familiale',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              DropdownButtonFormField<String>(
                value: _maritalStatus,
                decoration: const InputDecoration(
                  labelText: 'Situation matrimoniale',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Célibataire', child: Text('Célibataire')),
                  DropdownMenuItem(value: 'Marié', child: Text('Marié')),
                  DropdownMenuItem(value: 'PACS', child: Text('PACS')),
                  DropdownMenuItem(value: 'Divorcé', child: Text('Divorcé')),
                ],
                onChanged: (value) {
                  setState(() {
                    _maritalStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre d\'enfants'),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _numberOfChildren.toDouble(),
                            min: 0,
                            max: 10,
                            divisions: 10,
                            label: _numberOfChildren.toString(),
                            onChanged: (value) {
                              setState(() {
                                _numberOfChildren = value.toInt();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            _numberOfChildren.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                title: const Text('Je vis seul(e)'),
                value: _livesAlone,
                onChanged: (value) {
                  setState(() {
                    _livesAlone = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                title: const Text('J\'ai des animaux de compagnie'),
                value: _hasPets,
                onChanged: (value) {
                  setState(() {
                    _hasPets = value ?? false;
                  });
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
