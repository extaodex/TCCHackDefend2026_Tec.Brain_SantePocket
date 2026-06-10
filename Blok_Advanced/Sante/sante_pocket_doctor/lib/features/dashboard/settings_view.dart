import 'package:flutter/material.dart';
import '../../core/services/database_service.dart';
import '../../core/services/user_profile_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseService.getDoctorProfile();
    setState(() {
      _nameController.text = profile['name'] ?? '';
      _specialtyController.text = profile['specialty'] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final specialty = _specialtyController.text.trim();

    if (name.isNotEmpty) {
      await UserProfileService.saveDoctorName(name);
    }
    await DatabaseService.saveDoctorProfile(name, specialty);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paramètres', 
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            const Text('Personnalisez votre terminal médical et gérez votre profil professionnel.', 
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
            const SizedBox(height: 48),
            Container(
              constraints: const BoxConstraints(maxWidth: 700),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: Color(0xFF00695C), size: 24),
                      SizedBox(width: 12),
                      Text('Profil du Médecin', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildInputField('Nom Complet', _nameController, Icons.person, 'e.g. Dr. Jean Dupont'),
                  const SizedBox(height: 24),
                  _buildInputField('Spécialité', _specialtyController, Icons.medical_services_outlined, 'e.g. Cardiologue, Généraliste'),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('ENREGISTRER LES MODIFICATIONS', 
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blueGrey, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF00695C), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
