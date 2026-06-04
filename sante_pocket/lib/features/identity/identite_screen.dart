import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'patient_provider.dart';

class IdentiteScreen extends ConsumerWidget {
  const IdentiteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsyncValue = ref.watch(patientProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Identité & Constantes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.blueGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: patientAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Aucun profil patient trouvé.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(context, patient),
                const SizedBox(height: 32),
                Text('Mes Constantes', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                _buildConstantesGrid(context, patient),
                const SizedBox(height: 32),
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, dynamic patient) {
    final hasProfileImage = patient.imageProfilPath != null &&
        (patient.imageProfilPath as String).isNotEmpty &&
        File(patient.imageProfilPath).existsSync();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.premiumShadow(AppTheme.primaryBlueDark),
      ),
      child: Column(
        children: [
          // Photo de profil dynamique
          CircleAvatar(
            key: ValueKey(patient.imageProfilPath),
            radius: 50,
            backgroundColor: AppTheme.primaryBlueLight.withValues(alpha: 0.12),
            backgroundImage: hasProfileImage
                ? FileImage(File(patient.imageProfilPath))
                : null,
            child: !hasProfileImage
                ? Text(
                    '${(patient.prenom as String).isNotEmpty ? patient.prenom[0] : ''}${(patient.nom as String).isNotEmpty ? patient.nom[0] : ''}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlueLight,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text('${patient.prenom} ${patient.nom}', style: Theme.of(context).textTheme.headlineMedium),
          Text('Né le ${patient.dateNaissance}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleInfo('Sexe', patient.sexe.isNotEmpty ? patient.sexe : 'Non renseigné'),
              _buildSimpleInfo('Nationalité',
                  (patient.nationalite as String).isNotEmpty
                      ? patient.nationalite
                      : 'Non renseigné'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildConstantesGrid(BuildContext context, dynamic patient) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildDataCard(context, 'Groupe Sanguin', patient.groupeSanguin, Icons.bloodtype_rounded, Colors.redAccent),
        _buildDataCard(context, 'Taille', patient.taille.isNotEmpty ? patient.taille : '-', Icons.height_rounded, Colors.blueAccent),
        _buildDataCard(context, 'Poids', patient.poids.isNotEmpty ? patient.poids : '-', Icons.monitor_weight_rounded, Colors.orangeAccent),
        _buildDataCard(context, 'Tension', patient.tension.isNotEmpty ? patient.tension : '-', Icons.speed_rounded, Colors.greenAccent),
      ],
    );
  }

  Widget _buildDataCard(BuildContext context, String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow(accentColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 28),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: accentColor)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/edit-identite'),
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Modifier mes informations', style: TextStyle(color: Colors.white, fontSize: 18)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlueLight,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: AppTheme.primaryBlueLight.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
