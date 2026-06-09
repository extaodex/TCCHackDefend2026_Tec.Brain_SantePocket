import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../../core/services/pdf_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/desktop_secure_transfer_service.dart';

class ConsultationView extends ConsumerStatefulWidget {
  final Map<String, dynamic> patientRecord;

  const ConsultationView({super.key, required this.patientRecord});

  @override
  ConsumerState<ConsultationView> createState() => _ConsultationViewState();
}

class _ConsultationViewState extends ConsumerState<ConsultationView> {
  late Map<String, dynamic> _currentRecord;
  late TextEditingController _notesController;
  bool _isEditing = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentRecord = Map<String, dynamic>.from(widget.patientRecord);
    _notesController = TextEditingController(text: _currentRecord['notes']);
  }

  Future<void> _saveNotes() async {
    _currentRecord['notes'] = _notesController.text;
    await DatabaseService.savePatient(_currentRecord);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dossier mis à jour localement')),
      );
    }
  }

  Future<void> _sendToPatient() async {
    setState(() => _isSending = true);
    try {
      _currentRecord['notes'] = _notesController.text;
      await ref.read(secureTransferServiceProvider.notifier).returnToPatient(_currentRecord);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dossier renvoyé au patient avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'envoi : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _openFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await launchUrl(Uri.file(path));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier introuvable localement')),
        );
      }
    }
  }

  void _validateVaccination(int index) async {
    final dossier = Map<String, dynamic>.from(_currentRecord['dossier_clinique'] ?? {});
    final vaccinations = List<dynamic>.from(dossier['vaccinations'] ?? []);
    final updatedVaccine = Map<String, dynamic>.from(vaccinations[index]);
    updatedVaccine['statut_validation'] = 'VALIDE';
    vaccinations[index] = updatedVaccine;
    dossier['vaccinations'] = vaccinations;
    setState(() => _currentRecord['dossier_clinique'] = dossier);
    await DatabaseService.savePatient(_currentRecord);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vaccination validée')));
  }

  void _validateSymptom(int index) async {
    final dossier = Map<String, dynamic>.from(_currentRecord['dossier_clinique'] ?? {});
    final symptomes = List<dynamic>.from(dossier['symptomes'] ?? []);
    final updatedSymptom = Map<String, dynamic>.from(symptomes[index]);
    updatedSymptom['statut_validation'] = 'VALIDE';
    symptomes[index] = updatedSymptom;
    dossier['symptomes'] = symptomes;
    setState(() => _currentRecord['dossier_clinique'] = dossier);
    await DatabaseService.savePatient(_currentRecord);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Symptôme validé')));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final patientRecord = _currentRecord;
    final allergies = (patientRecord['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final name = patientRecord['nom'] ?? 'N/A';
    final firstName = patientRecord['prenom'] ?? 'N/A';
    final transferState = ref.watch(secureTransferServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Dossier Médical Numérique', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        actions: [
          if (transferState.remoteIp != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: FilledButton.icon(
                onPressed: _isSending ? null : _sendToPatient,
                icon: _isSending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_to_mobile_rounded, size: 18),
                label: Text(_isSending ? 'ENVOI...' : 'RENVOYER AU PATIENT', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => PdfService.generateAndPrint(patientRecord),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('IMPRIMER', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => PdfService.generateAndShare(patientRecord),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('EXPORTER PDF', style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00695C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientHeader(context, name, firstName, patientRecord),
            const SizedBox(height: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildCriticalInfo(context, allergies),
                      const SizedBox(height: 32),
                      _buildDocumentsList(context, patientRecord),
                      const SizedBox(height: 32),
                      _buildMedicalHistory(context, patientRecord),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildConsultationNotes(context, _notesController.text),
                      const SizedBox(height: 32),
                      _buildVitalsHistory(context, patientRecord),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.02, end: 0),
    );
  }

  Widget _buildPatientHeader(BuildContext context, String name, String firstName, Map<String, dynamic> record) {
    final colorScheme = Theme.of(context).colorScheme;
    final localImagePath = record['image_profil_local'] as String?;
    final dobVal = record['dob'] ?? record['date_naissance'];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [colorScheme.primary.withValues(alpha: 0.1), colorScheme.primary.withValues(alpha: 0.2)]), shape: BoxShape.circle, image: localImagePath != null && localImagePath.isNotEmpty ? DecorationImage(image: FileImage(File(localImagePath)), fit: BoxFit.cover) : null, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
            child: (localImagePath == null || localImagePath.isEmpty) ? Center(child: Text(name[0] + firstName[0], style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.primary))) : null,
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Text('$name $firstName', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1)), const SizedBox(width: 16), _buildBadge(record['groupeSanguin'] ?? '?', Colors.red)]),
                const SizedBox(height: 8),
                Row(children: [const Icon(Icons.cake_outlined, size: 16, color: Color(0xFF94A3B8)), const SizedBox(width: 8), Text('Né(e) le ${dobVal ?? 'N/A'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500)), const SizedBox(width: 16), const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF94A3B8)), const SizedBox(width: 8), Text(record['sexe'] ?? 'N/A', style: const TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500))]),
              ],
            ),
          ),
          _buildInfoTile('Taille', record['taille'] ?? 'N/A', Icons.height_rounded),
          _buildVerticalDivider(),
          _buildInfoTile('Poids', record['poids'] ?? 'N/A', Icons.monitor_weight_outlined),
          _buildVerticalDivider(),
          _buildInfoTile('Tension', record['tension'] ?? 'N/A', Icons.speed_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Column(children: [Icon(icon, size: 20, color: const Color(0xFF94A3B8)), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B)))]));
  }

  Widget _buildVerticalDivider() => Container(height: 48, width: 1.5, color: const Color(0xFFF1F5F9));

  Widget _buildBadge(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))), child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)));

  Widget _buildCriticalInfo(BuildContext context, List<String> allergies) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFFEE2E2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 28), const SizedBox(width: 16), const Text('Informations Critiques', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF991B1B)))]),
          const SizedBox(height: 24),
          const Text('ALLERGIES DÉTECTÉES :', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFFB91C1C), letterSpacing: 1)),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: allergies.isEmpty ? [const Text('Aucune allergie connue', style: TextStyle(color: Color(0xFF7F1D1D), fontStyle: FontStyle.italic))] : allergies.map((a) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]), child: Text(a, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)))).toList()),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(BuildContext context, Map<String, dynamic> record) {
    final docs = record['extracted_documents'] as Map<String, dynamic>? ?? {};
    final pdfs = docs.entries.where((e) => e.key.startsWith('documents/')).toList();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.folder_copy_rounded, color: Color(0xFF00695C), size: 24), const SizedBox(width: 16), const Text('Documents & Examens', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B)))]),
          const SizedBox(height: 32),
          if (pdfs.isEmpty) const Center(child: Text('Aucun document joint.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)))
          else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, mainAxisExtent: 80), itemCount: pdfs.length, itemBuilder: (context, i) {
            final name = p.basename(pdfs[i].key);
            return InkWell(onTap: () => _openFile(pdfs[i].value), borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))), child: Row(children: [const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 32), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))), const Text('Ouvrir le PDF', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold))]))])));
          }),
        ],
      ),
    );
  }

  Widget _buildMedicalHistory(BuildContext context, Map<String, dynamic> record) {
    final dossier = record['dossier_clinique'] as Map<String, dynamic>? ?? {};
    final consultations = dossier['consultations'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Historique des Visites', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B))), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.add_rounded), label: const Text('NOUVELLE VISITE', style: TextStyle(fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 24),
          if (consultations.isEmpty) const Center(child: Text('Aucun historique.', style: TextStyle(color: Color(0xFF94A3B8))))
          else ...consultations.map((c) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)), child: ListTile(leading: const Icon(Icons.event_available_rounded, color: Colors.blueGrey), title: Text(c['diagnostic'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Le ${c['date']}')))),
        ],
      ),
    );
  }

  Widget _buildConsultationNotes(BuildContext context, String notes) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rapport Médical', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF1E293B))), IconButton(icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded, color: const Color(0xFF00695C), size: 28), onPressed: _isEditing ? _saveNotes : () => setState(() => _isEditing = true))]),
          const SizedBox(height: 24),
          Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(24), border: Border.all(color: _isEditing ? const Color(0xFF00695C) : const Color(0xFFF1F5F9))), child: _isEditing ? TextField(controller: _notesController, maxLines: 10, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Saisissez vos observations...')) : Text(notes.isEmpty ? 'Aucune note rédigée.' : notes, style: const TextStyle(height: 1.6, fontSize: 15, color: Color(0xFF334155)))),
        ],
      ),
    );
  }

  Widget _buildVitalsHistory(BuildContext context, Map<String, dynamic> record) {
    final dossier = record['dossier_clinique'] as Map<String, dynamic>? ?? {};
    final symptomes = dossier['symptomes'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Symptômes Déclarés', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
          const SizedBox(height: 24),
          if (symptomes.isEmpty) const Text('Aucun symptôme récent.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontStyle: FontStyle.italic))
          else ...symptomes.map((s) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.history_edu_rounded, size: 18, color: Colors.orange), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s['date'], style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(s['description'], style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w500))]))]))),
        ],
      ),
    );
  }
}
