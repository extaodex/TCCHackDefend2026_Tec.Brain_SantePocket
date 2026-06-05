import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/database_service.dart';

class ConsultationView extends StatefulWidget {
  final Map<String, dynamic> patientRecord;

  const ConsultationView({super.key, required this.patientRecord});

  @override
  State<ConsultationView> createState() => _ConsultationViewState();
}

class _ConsultationViewState extends State<ConsultationView> {
  late TextEditingController _notesController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.patientRecord['notes']);
  }

  Future<void> _saveNotes() async {
    final updatedRecord = Map<String, dynamic>.from(widget.patientRecord);
    updatedRecord['notes'] = _notesController.text;
    await DatabaseService.savePatient(updatedRecord);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier mis à jour')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final patientRecord = widget.patientRecord;
    final allergies = (patientRecord['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final name = patientRecord['nom'] ?? 'N/A';
    final firstName = patientRecord['prenom'] ?? 'N/A';
    final hasData = patientRecord.isNotEmpty;

    if (!hasData) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.medical_information_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucun dossier patient sélectionné', style: TextStyle(color: Colors.grey, fontSize: 18)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dossier Médical Numérique'),
        centerTitle: false,
        actions: [
          OutlinedButton.icon(
            onPressed: () => PdfService.generateAndPrint(patientRecord),
            icon: const Icon(Icons.print),
            label: const Text('Imprimer'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => PdfService.generateAndShare(patientRecord),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exporter PDF'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(context, name, firstName, patientRecord),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildCriticalInfo(context, allergies),
                      const SizedBox(height: 24),
                      _buildMedicalHistory(context),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildConsultationNotes(context, _notesController.text),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildPatientHeader(BuildContext context, String name, String firstName, Map<String, dynamic> record) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primary.withAlpha((0.1 * 255).toInt()),
              child: Text(name[0] + firstName[0], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$name $firstName', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      _buildBadge(record['groupeSanguin'] ?? '?', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Né(e) le ${record['dob'] ?? 'N/A'} • 34 ans • Homme',
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16),
                  ),
                ],
              ),
            ),
            _buildInfoTile('Taille', '182 cm'),
            _buildVerticalDivider(),
            _buildInfoTile('Poids', '78 kg'),
            _buildVerticalDivider(),
            _buildInfoTile('Tension', '12/8'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.withAlpha((0.2 * 255).toInt()));
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((0.5 * 255).toInt())),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildCriticalInfo(BuildContext context, List<String> allergies) {
    return Card(
      color: Colors.red.shade50.withAlpha((0.5 * 255).toInt()),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.red.withAlpha((0.2 * 255).toInt())),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red),
                SizedBox(width: 12),
                Text('Informations Critiques', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('ALLERGIES DÉTECTÉES :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: allergies.isEmpty 
                ? [const Text('Aucune allergie connue', style: TextStyle(fontStyle: FontStyle.italic))]
                : allergies.map((allergy) => Chip(
                    label: Text(allergy, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.red,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistory(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Antécédents & Pathologies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            _buildHistoryItem('Asthme chronique', 'Depuis l\'enfance - Traitement Ventoline'),
            _buildHistoryItem('Fracture du fémur', '2018 - Chirurgie avec broche'),
            _buildHistoryItem('Hypertension artérielle', 'Suivi depuis 2022'),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.teal),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationNotes(BuildContext context, String? notes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rapport Médical', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.teal),
                  onPressed: _isEditing ? _saveNotes : () => setState(() => _isEditing = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isEditing ? Colors.teal.withAlpha(100) : Colors.grey.shade200),
              ),
              child: _isEditing
                  ? TextField(
                      controller: _notesController,
                      maxLines: 10,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Écrire le rapport...'),
                    )
                  : Text(
                      _notesController.text.isEmpty ? 'Aucun rapport rédigé.' : _notesController.text,
                      style: const TextStyle(height: 1.5, fontSize: 15),
                    ),
            ),
            const SizedBox(height: 24),
            const Text('Dernière mise à jour', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Text('Aujourd\'hui à 14:32', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
