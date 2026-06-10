import 'package:flutter/material.dart';
import '../../core/services/database_service.dart';
import '../consultation/consultation_view.dart';

class PatientsListView extends StatefulWidget {
  const PatientsListView({super.key});

  @override
  State<PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<PatientsListView> {
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final patients = await DatabaseService.getAllPatients();
    if (mounted) {
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _filteredPatients = _patients.where((p) {
        final fullName = '${p['nom']} ${p['prenom']}'.toLowerCase();
        return fullName.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Base Patients', 
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            const Text('Consultez, gérez et éditez les dossiers médicaux archivés localement.', 
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
            const SizedBox(height: 48),
            _buildSearchBar(colorScheme),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(100), child: CircularProgressIndicator()))
            else if (_filteredPatients.isEmpty)
              _buildEmptyState()
            else
              _buildPatientList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPatients,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          icon: Icon(Icons.search_rounded, color: Color(0xFF00695C)),
          hintText: 'Rechercher un dossier (Nom, Prénom)...',
          hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search_rounded, size: 64, color: Colors.blueGrey.shade200),
          ),
          const SizedBox(height: 24),
          const Text('Aucun patient trouvé', 
            style: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Essayez une autre recherche ou recevez un nouveau patient.', 
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        final name = (patient['nom'] ?? 'N/A').toUpperCase();
        final firstName = patient['prenom'] ?? '';
        final dob = patient['dob'] ?? 'N/A';
        final initials = (name.isNotEmpty ? name[0] : '?') + (firstName.isNotEmpty ? firstName[0] : '');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ConsultationView(patientRecord: patient)),
              ).then((_) => _loadPatients());
            },
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF00695C).withValues(alpha: 0.1), const Color(0xFF00695C).withValues(alpha: 0.2)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initials, 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00695C), fontSize: 18),
                ),
              ),
            ),
            title: Text('$name $firstName', 
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.cake_outlined, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Text(dob, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.bloodtype_outlined, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Text(patient['groupeSanguin'] ?? '?', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                  onPressed: () => _confirmDelete(patient['db_id']),
                  tooltip: 'Supprimer le dossier',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(String? id) async {
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le dossier ?'),
        content: const Text('Cette action est irréversible et supprimera toutes les données de ce patient localement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deletePatient(id);
      _loadPatients();
    }
  }
}
