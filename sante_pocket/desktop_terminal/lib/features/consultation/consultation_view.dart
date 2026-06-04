import 'package:flutter/material.dart';

class ConsultationView extends StatelessWidget {
  final Map<String, dynamic> patientRecord;

  const ConsultationView({super.key, required this.patientRecord});

  @override
  Widget build(BuildContext context) {
    final allergies = (patientRecord['allergies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Dossier Patient')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${patientRecord['nom'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleLarge),
            Text('Prénom: ${patientRecord['prenom'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleLarge),
            Text('Date de naissance: ${patientRecord['dob'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Groupe Sanguin: ${patientRecord['groupeSanguin'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Allergies:', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8.0,
              children: allergies.map((allergy) => Chip(label: Text(allergy))).toList(),
            ),
            const SizedBox(height: 10),
            Text('Notes Critiques:', style: Theme.of(context).textTheme.titleMedium),
            Text(patientRecord['notes'] ?? 'Aucune note'),
          ],
        ),
      ),
    );
  }
}
