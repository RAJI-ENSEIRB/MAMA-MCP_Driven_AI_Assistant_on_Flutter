import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../models/habitat_profile.dart';
import '../../app_state.dart';
import '../common/app_header.dart';
import '../common/robot_avatar.dart';

class HabitatEditPage extends StatefulWidget {
  const HabitatEditPage({super.key});

  @override
  State<HabitatEditPage> createState() => _HabitatEditPageState();
}

class _HabitatEditPageState extends State<HabitatEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _cityController = TextEditingController();
  String _selectedType = 'Appartement';
  int _selectedFloor = 0;

  bool _loading = true;
  late Box<HabitatProfile> _habitatBox;

  @override
  void initState() {
    super.initState();
    _habitatBox = Hive.box<HabitatProfile>('habitat_box');
    _load();
  }

  Future<void> _load() async {
    final profile = _habitatBox.get('profile');
    if (profile != null) {
      _cityController.text = profile.city;
      _selectedType = profile.type;
      _selectedFloor = profile.floor;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = HabitatProfile(
      city: _cityController.text.trim(),
      type: _selectedType,
      floor: _selectedFloor,
    );

    await _habitatBox.put('profile', profile);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Habitat enregistré')));
    Navigator.of(context).pop();
  }

  String _getOrdinal(int number) {
    if (number == 1) return 'er';
    return 'ème';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = context.watch<MyAppState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            pageTitle: 'Habitat',
            showBackButton: true,
            robotAvatar: RobotAvatar(state: state, theme: theme, compact: true),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
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
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vos informations de logement',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'Type de logement',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedType,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: cs.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: cs.outline.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: cs.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Maison',
                                    child: Text('Maison'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Studio',
                                    child: Text('Studio'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'T1',
                                    child: Text('T1'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'T2',
                                    child: Text('T2'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Appartement',
                                    child: Text('Appartement'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedType = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Ville',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  hintText: 'Entrez votre ville',
                                  filled: true,
                                  fillColor: cs.surface,
                                  prefixIcon: Icon(
                                    Icons.location_city,
                                    color: cs.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: cs.outline.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: cs.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez entrer votre ville';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Étage',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primary.withOpacity(0.08),
                                      cs.secondary.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.outline.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: _selectedFloor.toDouble(),
                                        min: -1,
                                        max: 10,
                                        divisions: 11,
                                        activeColor: cs.primary,
                                        inactiveColor: cs.primary.withOpacity(
                                          0.3,
                                        ),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [cs.primary, cs.secondary],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _selectedFloor == 0
                                            ? 'RDC'
                                            : '${_selectedFloor}${_getOrdinal(_selectedFloor)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [cs.primary, cs.secondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: FilledButton.icon(
                                  onPressed: _save,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Enregistrer'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
