import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/patient.dart';
import '../onboarding/onboarding_screen.dart';
import '../identity/patient_provider.dart';
import '../p2p_transfer/p2p_transfer_screen.dart';
import '../../core/services/msh_generator_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _calculateAge(String dateNaissance) {
    try {
      final parts = dateNaissance.split('/');
      if (parts.length != 3) return '?';
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final birth = DateTime(year, month, day);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
      return '$age ans';
    } catch (_) {
      return '?';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientProvider);

    return patientAsync.when(
      data: (patient) {
        if (patient == null) {
          return const OnboardingScreen();
        }
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(color: AppTheme.backgroundLight),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, patient),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text('Mon État de Santé',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('Carnet de santé numérique sécurisé',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 24),
                        _buildActionGrid(context),
                        const SizedBox(height: 32),
                        _buildP2PTransferSection(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlueLight),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Patient patient) {
    final nom = '${patient.prenom} ${patient.nom}';
    final initials = '${patient.prenom.isNotEmpty ? patient.prenom[0] : ''}${patient.nom.isNotEmpty ? patient.nom[0] : ''}';
    final age = _calculateAge(patient.dateNaissance);
    final subtitle = 'Groupe : ${patient.groupeSanguin} | $age';

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primaryBlueDark,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppTheme.blueGradient),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  // Avatar avec initiales ou photo
                  Container(
                    key: ValueKey(patient.imageProfilPath),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.white.withValues(alpha: 0.2),
                      image: patient.imageProfilPath.isNotEmpty
                          ? DecorationImage(
                              image: FileImage(File(patient.imageProfilPath)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: patient.imageProfilPath.isEmpty
                        ? Center(
                            child: Text(initials.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800)),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(nom,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                            const SizedBox(width: 6),
                            const Text('• P', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      ],
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

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _buildActionCard(context, 'Consultations', 'Visites & Suivi',
            Icons.history_rounded, AppTheme.blueGradient, '/consultations'),
        _buildActionCard(context, 'Urgences', 'Allergies & Contacts',
            Icons.warning_rounded, AppTheme.redGradient, '/urgences'),
        _buildActionCard(context, 'Vaccins', 'Suivi & Rappels',
            Icons.vaccines_rounded, AppTheme.greenGradient, '/vaccins'),
        _buildActionCard(context, 'Symptômes', 'Journal & Notes',
            Icons.history_edu_rounded, AppTheme.orangeGradient, '/symptomes'),
        _buildActionCard(context, 'Documents', 'Scanner & PDFs',
            Icons.document_scanner_rounded, AppTheme.blueGradient, '/documents'),
        _buildActionCard(context, 'Identité', 'Constantes & Profil',
            Icons.person_rounded, AppTheme.blueGradient, '/identite'),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    LinearGradient gradient,
    String route,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.premiumShadow(gradient.colors.last),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => context.push(route),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildP2PTransferSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Partage avec le médecin', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildP2PCard(
                context,
                'Partager avec médecin',
                'Envoyer mes données',
                Icons.send_rounded,
                AppTheme.blueGradient,
                () async {
                  final mshPath = await MshGeneratorService.generateMsh();
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => P2PTransferScreen(fileToShare: File(mshPath))));
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildP2PCard(
                context,
                'Attendre le médecin',
                'Recevoir les notes',
                Icons.download_rounded,
                AppTheme.greenGradient,
                () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const P2PTransferScreen()));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildP2PCard(BuildContext context, String title, String subtitle, IconData icon, LinearGradient gradient, VoidCallback onTap) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow(gradient.colors.last.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const Spacer(),
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
