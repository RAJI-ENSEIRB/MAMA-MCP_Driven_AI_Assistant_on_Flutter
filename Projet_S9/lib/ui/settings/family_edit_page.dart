import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../models/family_profile.dart';
import '../../app_state.dart';
import '../common/app_header.dart';
import '../common/robot_avatar.dart';

class FamilyEditPage extends StatefulWidget {
  const FamilyEditPage({super.key});

  @override
  State<FamilyEditPage> createState() => _FamilyEditPageState();
}

class _FamilyEditPageState extends State<FamilyEditPage> {
  final _formKey = GlobalKey<FormState>();
  String _maritalStatus = 'Célibataire';
  int _numberOfChildren = 0;
  bool _livesAlone = true;
  bool _hasPets = false;

  bool _loading = true;
  late Box<FamilyProfile> _familyBox;

  @override
  void initState() {
    super.initState();
    _familyBox = Hive.box<FamilyProfile>('family_box');
    _load();
  }

  Future<void> _load() async {
    final profile = _familyBox.get('profile');
    if (profile != null) {
      _maritalStatus = profile.maritalStatus;
      _numberOfChildren = profile.numberOfChildren;
      _livesAlone = profile.livesAlone;
      _hasPets = profile.hasPets;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = FamilyProfile(
      maritalStatus: _maritalStatus,
      numberOfChildren: _numberOfChildren,
      livesAlone: _livesAlone,
      hasPets: _hasPets,
    );

    await _familyBox.put('profile', profile);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Famille enregistré')));
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
            pageTitle: 'Famille',
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
                                'Vos informations familiales',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'Situation matrimoniale',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _maritalStatus,
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
                                    value: 'Célibataire',
                                    child: Text('Célibataire'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Marié',
                                    child: Text('Marié'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'PACS',
                                    child: Text('PACS'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Divorcé',
                                    child: Text('Divorcé'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _maritalStatus = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Nombre d\'enfants',
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
                                        value: _numberOfChildren.toDouble(),
                                        min: 0,
                                        max: 10,
                                        divisions: 10,
                                        activeColor: cs.primary,
                                        inactiveColor: cs.primary.withOpacity(
                                          0.3,
                                        ),
                                        label: _numberOfChildren.toString(),
                                        onChanged: (value) {
                                          setState(() {
                                            _numberOfChildren = value.toInt();
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
                                        _numberOfChildren.toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              Container(
                                padding: const EdgeInsets.all(12),
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
                                child: CheckboxListTile(
                                  title: const Text('Je vis seul(e)'),
                                  activeColor: cs.primary,
                                  value: _livesAlone,
                                  onChanged: (value) {
                                    setState(() {
                                      _livesAlone = value ?? true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.all(12),
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
                                child: CheckboxListTile(
                                  title: const Text(
                                    'J\'ai des animaux de compagnie',
                                  ),
                                  activeColor: cs.primary,
                                  value: _hasPets,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasPets = value ?? false;
                                    });
                                  },
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
