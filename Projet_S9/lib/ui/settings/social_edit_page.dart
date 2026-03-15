import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../models/social_profile.dart';
import '../../app_state.dart';
import '../common/app_header.dart';
import '../common/robot_avatar.dart';

class SocialEditPage extends StatefulWidget {
  const SocialEditPage({super.key});

  @override
  State<SocialEditPage> createState() => _SocialEditPageState();
}

class _SocialEditPageState extends State<SocialEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _activitiesController = TextEditingController();
  String _stressLevel = 'Modéré';
  String _sleepQuality = 'Moyenne';
  final _consumptionsController = TextEditingController();

  bool _loading = true;
  late Box<SocialProfile> _socialBox;

  @override
  void initState() {
    super.initState();
    _socialBox = Hive.box<SocialProfile>('social_box');
    _load();
  }

  Future<void> _load() async {
    final profile = _socialBox.get('profile');
    if (profile != null) {
      _activitiesController.text = profile.activities;
      _stressLevel = profile.stressLevel;
      _sleepQuality = profile.sleepQuality;
      _consumptionsController.text = profile.consumptions;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _activitiesController.dispose();
    _consumptionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = SocialProfile(
      activities: _activitiesController.text.trim(),
      stressLevel: _stressLevel,
      sleepQuality: _sleepQuality,
      consumptions: _consumptionsController.text.trim(),
    );

    await _socialBox.put('profile', profile);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Infos sociales enregistrées')),
    );
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
            pageTitle: 'Social & Bien-être',
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
                                'Vos informations sociales et bien-être',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'Activités et loisirs (optionnel)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _activitiesController,
                                decoration: InputDecoration(
                                  hintText: 'Décrivez vos activités et loisirs',
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
                                maxLines: 2,
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Niveau de stress',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _stressLevel,
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
                                    value: 'Faible',
                                    child: Text('Faible'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Modéré',
                                    child: Text('Modéré'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Élevé',
                                    child: Text('Élevé'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _stressLevel = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Qualité du sommeil',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _sleepQuality,
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
                                    value: 'Mauvaise',
                                    child: Text('Mauvaise'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Moyenne',
                                    child: Text('Moyenne'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Bonne',
                                    child: Text('Bonne'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _sleepQuality = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Consommations (alcool, tabac, etc) (optionnel)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _consumptionsController,
                                decoration: InputDecoration(
                                  hintText: 'Décrivez vos consommations',
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
                                maxLines: 2,
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
