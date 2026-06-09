import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/user_profile_service.dart';

class OnboardingView extends StatefulWidget {
  final VoidCallback onOnboardingComplete;

  const OnboardingView({super.key, required this.onOnboardingComplete});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      // On s'assure que le nom commence par "Dr. " pour le terminal médecin
      final formattedName = name.toLowerCase().startsWith('dr.') || name.toLowerCase().startsWith('dr ')
          ? name
          : 'Dr. $name';

      await UserProfileService.saveDoctorName(formattedName);
      widget.onOnboardingComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          // Section gauche décorative (Visual Wow)
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: GridPaper(
                        color: Colors.white,
                        divisions: 1,
                        subdivisions: 1,
                        interval: 40,
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.health_and_safety_rounded,
                            size: 100,
                            color: Colors.white,
                          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 24),
                          Text(
                            'Santé Pocket',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                          const SizedBox(height: 12),
                          Text(
                            'Terminal Médecin — Transfert P2P chiffré ultra-rapide sans connexion Internet.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white.withAlpha(204),
                              height: 1.5,
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Section droite (Formulaire)
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Bienvenue',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(),
                        const SizedBox(height: 8),
                        Text(
                          'Configurez votre identité pour commencer à échanger des dossiers médicaux.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom du médecin',
                            hintText: 'Ex: Tcha',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Commencer',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
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
