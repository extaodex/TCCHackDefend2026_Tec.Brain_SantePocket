import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/patient.dart';
import '../identity/patient_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1 fields
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  DateTime? _selectedDate;

  // Page 2 fields
  String? _selectedSexe;

  // Page 3 fields
  String? _selectedGroupe;

  // Page 4 fields
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();
  final _tensionController = TextEditingController();

  final List<String> _groupesSanguins = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _tensionController.dispose();
    super.dispose();
  }

  /// Ouvre le calendrier natif pour sélectionner la date de naissance
  Future<void> _pickDateNaissance() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now, // Impossible de sélectionner une date future
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionnez votre date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      fieldLabelText: 'Date de naissance',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryBlueLight,
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
            datePickerTheme: const DatePickerThemeData(backgroundColor: Color(0xFF1E293B)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.emergencyRedLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == 0) {
      final nom = _nomController.text.trim();
      final prenom = _prenomController.text.trim();
      if (nom.isEmpty || prenom.isEmpty || _selectedDate == null) {
        _showError(_selectedDate == null
            ? 'Veuillez sélectionner votre date de naissance'
            : 'Veuillez remplir votre nom et prénom correctement');
        return;
      }
    }
    if (_currentPage == 1 && _selectedSexe == null) {
      _showError('Veuillez choisir votre sexe');
      return;
    }
    if (_currentPage == 2 && _selectedGroupe == null) {
      // On autorise maintenant à passer sans choisir le groupe sanguin
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding() async {
    final taille = _tailleController.text.trim();
    final poids = _poidsController.text.trim();
    final tension = _tensionController.text.trim();

    // Validations
    if (taille.isNotEmpty && double.tryParse(taille) == null) {
      _showError('La taille doit être un nombre (ex: 180)');
      return;
    }
    if (poids.isNotEmpty && double.tryParse(poids) == null) {
      _showError('Le poids doit être un nombre (ex: 75)');
      return;
    }
    if (tension.isNotEmpty) {
      final tensionRegex = RegExp(r'^\d{1,2}/\d{1,2}$');
      if (!tensionRegex.hasMatch(tension)) {
        _showError('Format tension invalide (ex: 12/8)');
        return;
      }
    }

    // Confirmation pour le groupe sanguin s'il est renseigné
    if (_selectedGroupe != null) {
      final confirmer = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Confirmer le groupe sanguin', style: TextStyle(color: Colors.white)),
          content: Text(
            'Vous avez choisi le groupe : $_selectedGroupe.\n\nAttention, une fois enregistré, cette information ne pourra plus être modifiée.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.validatedGreenLight),
              child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmer != true) return;
    }

    final dateFormatted = DateFormat('dd/MM/yyyy').format(_selectedDate!);

    final patient = Patient(
      id: 1,
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      dateNaissance: dateFormatted,
      groupeSanguin: _selectedGroupe ?? '',
      allergies: '',
      sexe: _selectedSexe!,
      taille: _tailleController.text.trim(),
      poids: _poidsController.text.trim(),
      tension: _tensionController.text.trim(),
    );

    await ref.read(patientProvider.notifier).savePatient(patient);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator & Back button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: index <= _currentPage
                                ? AppTheme.primaryBlueLight
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_currentPage > 0) const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildInfoPage(),
                  _buildSexePage(),
                  _buildGroupeSanguinPage(),
                  _buildConstantesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Nom, Prénom, Date de Naissance (Calendrier) ──
  Widget _buildInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.blueGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.medical_information_rounded, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Bienvenue dans\nMémoSanté Pocket',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Vos données restent sur votre appareil, chiffrées et sécurisées.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 40),
          _buildDarkField('Nom', _nomController, Icons.person_rounded),
          const SizedBox(height: 16),
          _buildDarkField('Prénom', _prenomController, Icons.badge_rounded),
          const SizedBox(height: 16),

          // ── Date de naissance via CALENDRIER ──
          GestureDetector(
            onTap: _pickDateNaissance,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: _selectedDate != null
                    ? Border.all(color: AppTheme.primaryBlueLight.withValues(alpha: 0.5), width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: _selectedDate != null ? AppTheme.primaryBlueLight : Colors.white30,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate!)
                          : 'Date de naissance (appuyez pour choisir)',
                      style: TextStyle(
                        color: _selectedDate != null ? Colors.white : Colors.white30,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_selectedDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.validatedGreenLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_rounded, color: AppTheme.validatedGreenLight, size: 16),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
          _buildContinueButton('Continuer', _nextPage),
        ],
      ),
    );
  }

  // ── Page 2: Choix du Sexe ──
  Widget _buildSexePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wc_rounded, color: Colors.white38, size: 60),
          const SizedBox(height: 24),
          Text('Quel est votre sexe ?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text('Ce choix ne pourra pas être modifié ensuite.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 48),
          Row(
            children: [
              Expanded(child: _buildSexeCard('Masculin', Icons.male_rounded, AppTheme.primaryBlueLight)),
              const SizedBox(width: 20),
              Expanded(child: _buildSexeCard('Féminin', Icons.female_rounded, const Color(0xFFE91E8C))),
            ],
          ),
          const SizedBox(height: 48),
          _buildContinueButton('Continuer', _nextPage),
        ],
      ),
    );
  }

  Widget _buildSexeCard(String label, IconData icon, Color color) {
    final isSelected = _selectedSexe == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSexe = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 56, color: isSelected ? color : Colors.white38),
            const SizedBox(height: 12),
            Text(label,
              style: TextStyle(
                color: isSelected ? color : Colors.white54,
                fontSize: 18, fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 3: Groupe Sanguin ──
  Widget _buildGroupeSanguinPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.emergencyRedLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.bloodtype_rounded, color: AppTheme.emergencyRedLight, size: 44),
          ),
          const SizedBox(height: 24),
          Text('Groupe Sanguin',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text('Information essentielle en cas d\'urgence médicale. (Facultatif)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _groupesSanguins.map((g) => _buildGroupeChip(g)).toList(),
          ),
          const SizedBox(height: 48),
          _buildContinueButton(
            _selectedGroupe == null ? 'Passer cette étape' : 'Continuer',
            _nextPage,
            isPrimary: _selectedGroupe != null,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupeChip(String groupe) {
    final isSelected = _selectedGroupe == groupe;
    return GestureDetector(
      onTap: () => setState(() => _selectedGroupe = groupe),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.emergencyRedLight.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.emergencyRedLight : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Center(
          child: Text(groupe,
            style: TextStyle(
              color: isSelected ? AppTheme.emergencyRedLight : Colors.white60,
              fontSize: 20, fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  // ── Page 4: Constantes Physiques ──
  Widget _buildConstantesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.pendingOrangeLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.monitor_weight_rounded, color: AppTheme.pendingOrangeLight, size: 44),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Constantes\nPhysiques',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Facultatif. Vous pouvez les ajouter plus tard.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 40),
          _buildDarkField('Taille (en cm)', _tailleController, Icons.height_rounded, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildDarkField('Poids (en kg)', _poidsController, Icons.monitor_weight_rounded, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildDarkField('Tension (ex: 12/8)', _tensionController, Icons.favorite_rounded, keyboardType: TextInputType.text),
          const SizedBox(height: 40),
          _buildContinueButton(
            _tailleController.text.isEmpty && _poidsController.text.isEmpty && _tensionController.text.isEmpty
                ? 'Terminer plus tard'
                : 'Créer mon dossier',
            _finishOnboarding,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ──
  Widget _buildDarkField(String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: Icon(icon, color: Colors.white30, size: 22),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildContinueButton(String label, VoidCallback onTap, {bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.validatedGreenLight : AppTheme.primaryBlueLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
