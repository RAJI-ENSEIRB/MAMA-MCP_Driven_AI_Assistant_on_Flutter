import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../../models/mobility_profile.dart';
import '../../app_state.dart';
import '../common/app_header.dart';
import '../common/robot_avatar.dart';

class MobilityEditPage extends StatefulWidget {
  const MobilityEditPage({super.key});

  @override
  State<MobilityEditPage> createState() => _MobilityEditPageState();
}

class _MobilityEditPageState extends State<MobilityEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _hasDrivingLicense = true;
  String _primaryTransport = 'Voiture';
  final List<String> _availableTransports = [
    'Voiture',
    'Transports en commun',
    'Vélo',
    'A pied',
    'Scooter',
    'Moto',
  ];
  Set<String> _selectedTransports = {'Voiture'};

  bool _loading = true;
  late Box<MobilityProfile> _mobilityBox;

  @override
  void initState() {
    super.initState();
    _mobilityBox = Hive.box<MobilityProfile>('mobility_box');
    _load();
  }

  Future<void> _load() async {
    final profile = _mobilityBox.get('profile');
    if (profile != null) {
      _hasDrivingLicense = profile.hasDrivingLicense;
      _primaryTransport = profile.primaryTransport;
      _selectedTransports = profile.otherTransports.toSet();
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = MobilityProfile(
      hasDrivingLicense: _hasDrivingLicense,
      primaryTransport: _primaryTransport,
      otherTransports: _selectedTransports.toList(),
    );

    await _mobilityBox.put('profile', profile);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mobilité enregistrée')));
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
            pageTitle: 'Mobilité',
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
                                'Vos informations de mobilité',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 24),

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
                                    'J\'ai le permis de conduire',
                                  ),
                                  activeColor: cs.primary,
                                  value: _hasDrivingLicense,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasDrivingLicense = value ?? true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              Text(
                                'Moyen de transport principal',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _primaryTransport,
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
                                items: _availableTransports
                                    .map(
                                      (transport) => DropdownMenuItem(
                                        value: transport,
                                        child: Text(transport),
                                      ),
                                    )
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

                              Text(
                                'Autres moyens utilisés',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._availableTransports.map((transport) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
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
                                    dense: true,
                                    title: Text(transport),
                                    activeColor: cs.primary,
                                    value: _selectedTransports.contains(
                                      transport,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedTransports.add(transport);
                                        } else {
                                          _selectedTransports.remove(transport);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }).toList(),

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
