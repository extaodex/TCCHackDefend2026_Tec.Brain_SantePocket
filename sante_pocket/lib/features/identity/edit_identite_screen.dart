import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../../models/patient.dart';
import 'patient_provider.dart';

/// Liste complète des pays du monde (triée alphabétiquement, en français)
const List<String> _tousLesPays = [
  'Afghanistan', 'Afrique du Sud', 'Albanie', 'Algérie', 'Allemagne', 'Andorre',
  'Angola', 'Antigua-et-Barbuda', 'Arabie Saoudite', 'Argentine', 'Arménie',
  'Australie', 'Autriche', 'Azerbaïdjan', 'Bahamas', 'Bahreïn', 'Bangladesh',
  'Barbade', 'Belgique', 'Belize', 'Bénin', 'Bhoutan', 'Biélorussie',
  'Birmanie', 'Bolivie', 'Bosnie-Herzégovine', 'Botswana', 'Brésil', 'Brunei',
  'Bulgarie', 'Burkina Faso', 'Burundi', 'Cambodge', 'Cameroun', 'Canada',
  'Cap-Vert', 'Centrafrique', 'Chili', 'Chine', 'Chypre', 'Colombie',
  'Comores', 'Corée du Nord', 'Corée du Sud', 'Costa Rica', 'Côte d\'Ivoire',
  'Croatie', 'Cuba', 'Danemark', 'Djibouti', 'Dominique', 'Égypte',
  'Émirats arabes unis', 'Équateur', 'Érythrée', 'Espagne', 'Estonie',
  'Eswatini', 'États-Unis', 'Éthiopie', 'Fidji', 'Finlande', 'France',
  'Gabon', 'Gambie', 'Géorgie', 'Ghana', 'Grèce', 'Grenade', 'Guatemala',
  'Guinée', 'Guinée équatoriale', 'Guinée-Bissau', 'Guyana', 'Haïti',
  'Honduras', 'Hongrie', 'Inde', 'Indonésie', 'Irak', 'Iran', 'Irlande',
  'Islande', 'Israël', 'Italie', 'Jamaïque', 'Japon', 'Jordanie',
  'Kazakhstan', 'Kenya', 'Kirghizistan', 'Kiribati', 'Koweït', 'Laos',
  'Lesotho', 'Lettonie', 'Liban', 'Liberia', 'Libye', 'Liechtenstein',
  'Lituanie', 'Luxembourg', 'Macédoine du Nord', 'Madagascar', 'Malaisie',
  'Malawi', 'Maldives', 'Mali', 'Malte', 'Maroc', 'Maurice', 'Mauritanie',
  'Mexique', 'Micronésie', 'Moldavie', 'Monaco', 'Mongolie', 'Monténégro',
  'Mozambique', 'Namibie', 'Nauru', 'Népal', 'Nicaragua', 'Niger', 'Nigeria',
  'Norvège', 'Nouvelle-Zélande', 'Oman', 'Ouganda', 'Ouzbékistan', 'Pakistan',
  'Palaos', 'Palestine', 'Panama', 'Papouasie-Nouvelle-Guinée', 'Paraguay',
  'Pays-Bas', 'Pérou', 'Philippines', 'Pologne', 'Portugal', 'Qatar',
  'République dominicaine', 'République tchèque', 'Roumanie', 'Royaume-Uni',
  'Russie', 'Rwanda', 'Saint-Kitts-et-Nevis', 'Saint-Vincent-et-les-Grenadines',
  'Sainte-Lucie', 'Salomon', 'Salvador', 'Samoa', 'São Tomé-et-Príncipe',
  'Sénégal', 'Serbie', 'Seychelles', 'Sierra Leone', 'Singapour', 'Slovaquie',
  'Slovénie', 'Somalie', 'Soudan', 'Soudan du Sud', 'Sri Lanka', 'Suède',
  'Suisse', 'Suriname', 'Syrie', 'Tadjikistan', 'Tanzanie', 'Tchad',
  'Thaïlande', 'Timor oriental', 'Togo', 'Tonga', 'Trinité-et-Tobago',
  'Tunisie', 'Turkménistan', 'Turquie', 'Tuvalu', 'Ukraine', 'Uruguay',
  'Vanuatu', 'Vatican', 'Venezuela', 'Viêt Nam', 'Yémen', 'Zambie', 'Zimbabwe',
];

class EditIdentiteScreen extends ConsumerStatefulWidget {
  const EditIdentiteScreen({super.key});

  @override
  ConsumerState<EditIdentiteScreen> createState() => _EditIdentiteScreenState();
}

class _EditIdentiteScreenState extends ConsumerState<EditIdentiteScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _groupeSanguinController;
  late TextEditingController _allergiesController;
  late TextEditingController _tailleController;
  late TextEditingController _poidsController;
  late TextEditingController _tensionController;

  String _sexeReadOnly = '';
  DateTime? _selectedDate;
  String? _selectedNationalite;
  String? _imageProfilPath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final patient = ref.read(patientProvider).value;
    _nomController = TextEditingController(text: patient?.nom ?? '');
    _prenomController = TextEditingController(text: patient?.prenom ?? '');
    _groupeSanguinController = TextEditingController(text: patient?.groupeSanguin ?? '');
    _allergiesController = TextEditingController(text: patient?.allergies ?? '');
    _tailleController = TextEditingController(text: patient?.taille ?? '');
    _poidsController = TextEditingController(text: patient?.poids ?? '');
    _tensionController = TextEditingController(text: patient?.tension ?? '');
    _sexeReadOnly = patient?.sexe ?? '';
    _selectedNationalite = (patient?.nationalite ?? '').isNotEmpty ? patient!.nationalite : null;
    _imageProfilPath = (patient?.imageProfilPath ?? '').isNotEmpty ? patient!.imageProfilPath : null;

    // Parse la date existante
    if (patient != null && patient.dateNaissance.isNotEmpty) {
      try {
        _selectedDate = DateFormat('dd/MM/yyyy').parseStrict(patient.dateNaissance);
      } catch (_) {
        _selectedDate = null;
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _groupeSanguinController.dispose();
    _allergiesController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _tensionController.dispose();
    super.dispose();
  }

  /// Ouvre le calendrier pour la date de naissance
  Future<void> _pickDateNaissance() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionnez votre date de naissance',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlueLight,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Sélection de la photo de profil depuis la galerie
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null) {
      // Copier dans le répertoire de l'app pour persister
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory(p.join(appDir.path, 'profile'));
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      final ext = p.extension(image.path);
      // Generate a unique name to bypass FileImage caching
      final destPath = p.join(profileDir.path, 'avatar_${DateTime.now().millisecondsSinceEpoch}$ext');
      
      // Delete old image to save space
      if (_imageProfilPath != null && File(_imageProfilPath!).existsSync()) {
        try {
          File(_imageProfilPath!).deleteSync();
        } catch (_) {}
      }

      await File(image.path).copy(destPath);
      setState(() => _imageProfilPath = destPath);
    }
  }

  /// Ouvre un bottom sheet de recherche pour la nationalité
  void _pickNationalite() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = _tousLesPays
                .where((p) => p.toLowerCase().contains(search.toLowerCase()))
                .toList();
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) => setSheetState(() => search = v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un pays...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.07),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) {
                        final pays = filtered[index];
                        final isSelected = pays == _selectedNationalite;
                        return ListTile(
                          leading: Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.public_rounded,
                            color: isSelected ? AppTheme.validatedGreenLight : Colors.white38,
                          ),
                          title: Text(
                            pays,
                            style: TextStyle(
                              color: isSelected ? AppTheme.validatedGreenLight : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedNationalite = pays);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sauvegarder() async {
    if (_formKey.currentState!.validate()) {
      final patient = ref.read(patientProvider).value;

      final dateFormatted = _selectedDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
          : patient?.dateNaissance ?? '01/01/2000';

      final updatedPatient = Patient(
        id: patient?.id ?? 1,
        nom: _nomController.text,
        prenom: _prenomController.text,
        dateNaissance: dateFormatted,
        groupeSanguin: _groupeSanguinController.text,
        allergies: _allergiesController.text,
        sexe: _sexeReadOnly,
        taille: _tailleController.text,
        poids: _poidsController.text,
        tension: _tensionController.text,
        nationalite: _selectedNationalite ?? '',
        imageProfilPath: _imageProfilPath ?? '',
      );

      // Afficher un loader pendant la sauvegarde
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await ref.read(patientProvider.notifier).savePatient(updatedPatient);
        
        if (mounted) {
          // Fermer le loader
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Profil mis à jour avec succès'),
              backgroundColor: AppTheme.validatedGreenLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );

          context.pop();
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur lors de la sauvegarde : $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: AppTheme.primaryBlueDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo de profil ──
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        key: ValueKey(_imageProfilPath), // Force refresh
                        radius: 56,
                        backgroundColor: AppTheme.primaryBlueLight.withValues(alpha: 0.15),
                        backgroundImage: _imageProfilPath != null && File(_imageProfilPath!).existsSync()
                            ? FileImage(File(_imageProfilPath!))
                            : null,
                        child: _imageProfilPath == null || !File(_imageProfilPath!).existsSync()
                            ? const Icon(Icons.person_rounded, size: 48, color: AppTheme.primaryBlueLight)
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlueLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Appuyez pour changer la photo',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ),
              const SizedBox(height: 24),

              // Sexe - Champ verrouillé
              _buildReadOnlyField('Sexe (non modifiable)', _sexeReadOnly,
                icon: _sexeReadOnly == 'Masculin' ? Icons.male_rounded : Icons.female_rounded,
                iconColor: _sexeReadOnly == 'Masculin' ? AppTheme.primaryBlueDark : const Color(0xFFE91E8C),
              ),
              const SizedBox(height: 16),
              _buildTextField('Nom', _nomController),
              const SizedBox(height: 16),
              _buildTextField('Prénom', _prenomController),
              const SizedBox(height: 16),

              // ── Date de naissance (Calendrier) ──
              Text('Date de naissance', style: TextStyle(
                color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDateNaissance,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedDate != null
                          ? AppTheme.primaryBlueLight.withValues(alpha: 0.4)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                        color: _selectedDate != null ? AppTheme.primaryBlueLight : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate!)
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _selectedDate != null ? AppTheme.textDark : Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        Icon(Icons.check_circle_rounded, color: AppTheme.validatedGreenLight, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Nationalité (Liste pays) ──
              Text('Nationalité', style: TextStyle(
                color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickNationalite,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedNationalite != null
                          ? AppTheme.primaryBlueLight.withValues(alpha: 0.4)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public_rounded,
                        color: _selectedNationalite != null ? AppTheme.primaryBlueLight : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedNationalite ?? 'Sélectionner un pays',
                          style: TextStyle(
                            color: _selectedNationalite != null ? AppTheme.textDark : Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: _selectedNationalite != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField('Groupe Sanguin', _groupeSanguinController),
              const SizedBox(height: 16),
              _buildTextField('Taille (ex: 182 cm)', _tailleController),
              const SizedBox(height: 16),
              _buildTextField('Poids (ex: 78 kg)', _poidsController),
              const SizedBox(height: 16),
              _buildTextField('Tension (ex: 12/8)', _tensionController),
              const SizedBox(height: 16),
              _buildTextField('Allergies', _allergiesController, maxLines: 3),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sauvegarder,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.validatedGreenLight,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, {IconData? icon, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.grey, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? 'Non renseigné' : value,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 18),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
