import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habitat_profile.dart';

class HabitatPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const HabitatPage({super.key, required this.onComplete, required this.onSkip});

  @override
  State<HabitatPage> createState() => _HabitatPageState();
}

class _HabitatPageState extends State<HabitatPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Appartement';
  final _cityController = TextEditingController();
  int _selectedFloor = 0;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<HabitatProfile>('habitat_box');
      final profile = HabitatProfile(
        type: _selectedType,
        city: _cityController.text.trim(),
        floor: _selectedFloor,
      );
      await box.put('profile', profile);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitat'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Catégorie 2 / 7',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Parlez-nous de votre habitat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type de logement',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Maison', child: Text('Maison')),
                  DropdownMenuItem(value: 'Studio', child: Text('Studio')),
                  DropdownMenuItem(value: 'T1', child: Text('T1')),
                  DropdownMenuItem(value: 'T2', child: Text('T2')),
                  DropdownMenuItem(value: 'Appartement', child: Text('Appartement')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer votre ville';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Étage'),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _selectedFloor.toDouble(),
                            min: -1,
                            max: 10,
                            divisions: 11,
                            label: _selectedFloor == 0
                                ? 'RDC'
                                : '${_selectedFloor}${_getOrdinal(_selectedFloor)}',
                            onChanged: (value) {
                              setState(() {
                                _selectedFloor = value.toInt();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            _selectedFloor == 0
                                ? 'RDC'
                                : '${_selectedFloor}${_getOrdinal(_selectedFloor)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

  String _getOrdinal(int number) {
    if (number == 1) return 'er';
    return 'ème';
  }
}
