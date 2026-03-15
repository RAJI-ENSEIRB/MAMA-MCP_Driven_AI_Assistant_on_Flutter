import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../models/profession_profile.dart';
import '../../app_state.dart';
import '../common/app_header.dart';
import '../common/robot_avatar.dart';

class ProfessionEditPage extends StatefulWidget {
  const ProfessionEditPage({super.key});

  @override
  State<ProfessionEditPage> createState() => _ProfessionEditPageState();
}

class _ProfessionEditPageState extends State<ProfessionEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _jobController = TextEditingController();
  String _timeStatus = 'Temps plein';
  String _workLocation = 'Bureau';
  final _distanceController = TextEditingController();

  bool _loading = true;
  late Box<ProfessionProfile> _professionBox;

  @override
  void initState() {
    super.initState();
    _professionBox = Hive.box<ProfessionProfile>('profession_box');
    _load();
  }

  Future<void> _load() async {
    final profile = _professionBox.get('profile');
    if (profile != null) {
      _jobController.text = profile.job;
      _timeStatus = profile.timeStatus;
      _workLocation = profile.workLocation;
      _distanceController.text = profile.commutingDistance.toString();
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _jobController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ProfessionProfile(
      job: _jobController.text.trim(),
      timeStatus: _timeStatus,
      workLocation: _workLocation,
      commutingDistance: int.parse(_distanceController.text),
    );

    await _professionBox.put('profile', profile);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profession enregistrée')));
    Navigator.of(context).pop();
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
            pageTitle: 'Profession',
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
                                'Vos informations professionnelles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'Métier',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _jobController,
                                decoration: InputDecoration(
                                  hintText: 'ex: Ingénieur',
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
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez entrer votre métier';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Temps de travail',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _timeStatus,
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
                                    value: 'Temps plein',
                                    child: Text('Temps plein'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Temps partiel',
                                    child: Text('Temps partiel'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Indépendant',
                                    child: Text('Indépendant'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _timeStatus = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Lieu de travail',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _workLocation,
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
                                    value: 'Bureau',
                                    child: Text('Bureau'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Télétravail',
                                    child: Text('Télétravail'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Hybride',
                                    child: Text('Hybride'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _workLocation = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Distance trajet (km)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _distanceController,
                                decoration: InputDecoration(
                                  hintText: 'ex: 25',
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
