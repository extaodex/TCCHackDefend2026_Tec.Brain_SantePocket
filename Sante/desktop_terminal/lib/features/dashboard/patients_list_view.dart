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
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mes Patients', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text('Gérez et consultez les dossiers archivés.', style: TextStyle(color: Colors.blueGrey.shade400)),
            const SizedBox(height: 32),
            _buildSearchBar(colorScheme),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPatients.isEmpty
                      ? _buildEmptyState()
                      : _buildPatientList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterPatients,
        decoration: const InputDecoration(
          icon: Icon(Icons.search),
          hintText: 'Rechercher par nom ou prénom...',
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
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Aucun patient trouvé.', style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildPatientList() {
    return ListView.builder(
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ConsultationView(patientRecord: patient)),
              ).then((_) => _loadPatients());
            },
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
              child: Text((patient['nom']?[0] ?? '?') + (patient['prenom']?[0] ?? '?')),
            ),
            title: Text('${(patient['nom'] ?? 'N/A').toUpperCase()} ${patient['prenom'] ?? ''}', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Né(e) le ${patient['dob'] ?? 'N/A'} • Groupe: ${patient['groupeSanguin'] ?? '?'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(patient['db_id']),
                ),
                const Icon(Icons.chevron_right),
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
