import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mobility_profile.dart';

class MobilityPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const MobilityPage({super.key, required this.onComplete, required this.onSkip});

  @override
  State<MobilityPage> createState() => _MobilityPageState();
}

class _MobilityPageState extends State<MobilityPage> {
  final _formKey = GlobalKey<FormState>();
  bool _hasDrivingLicense = true;
  String _primaryTransport = 'Voiture';
  final List<String> _availableTransports = [
    'Voiture',
    'Transports en commun',
    'Vélo',
    'A pied',
    'Scooter',
    'Moto'
  ];
  Set<String> _selectedTransports = {'Voiture'};

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<MobilityProfile>('mobility_box');
      final profile = MobilityProfile(
        hasDrivingLicense: _hasDrivingLicense,
        primaryTransport: _primaryTransport,
        otherTransports: _selectedTransports.toList(),
      );
      await box.put('profile', profile);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobilité'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Catégorie 6 / 7',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Votre mobilité',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              CheckboxListTile(
                title: const Text('J\'ai le permis de conduire'),
                value: _hasDrivingLicense,
                onChanged: (value) {
                  setState(() {
                    _hasDrivingLicense = value ?? true;
                  });
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _primaryTransport,
                decoration: const InputDecoration(
                  labelText: 'Moyen de transport principal',
                  border: OutlineInputBorder(),
                ),
                items: _availableTransports
                    .map((transport) => DropdownMenuItem(
                          value: transport,
                          child: Text(transport),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _primaryTransport = value!;
                    if (!_selectedTransports.contains(value)) {
                      _selectedTransports.add(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Autres moyens utilisés',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._availableTransports.map((transport) {
                return CheckboxListTile(
                  title: Text(transport),
                  value: _selectedTransports.contains(transport),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedTransports.add(transport);
                      } else {
                        _selectedTransports.remove(transport);
                      }
                    });
                  },
                );
              }).toList(),

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
