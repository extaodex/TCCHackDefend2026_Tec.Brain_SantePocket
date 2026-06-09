import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ordonnance.dart';
import 'consultations_provider.dart';

class ConsultationsScreen extends ConsumerWidget {
  const ConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationsAsync = ref.watch(consultationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Historique Médical'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.blueGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: consultationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlueLight)),
        error: (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: Colors.red))),
        data: (consultations) {
          if (consultations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    const Text('Aucune consultation',
                        style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text(
                      'L\'historique de vos visites chez le médecin s\'affichera ici après synchronisation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white30, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              final c = consultations[index];
              final isValide = c.statutValidation == 'VALIDE';
              final color = isValide ? AppTheme.primaryBlueLight : AppTheme.pendingOrangeLight;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.medical_services_rounded, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(c.diagnostic,
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                        if (isValide)
                          const Icon(Icons.verified_user_rounded, color: AppTheme.validatedGreenLight, size: 20),
                      ],
                    ),
                    if (c.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(c.notes, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                    const SizedBox(height: 12),
                    _OrdonnanceButton(consultationId: c.id!),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrdonnanceButton extends ConsumerWidget {
  final int consultationId;
  const _OrdonnanceButton({required this.consultationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Ordonnance?>(
      future: ref.read(consultationsProvider.notifier).getOrdonnance(consultationId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final Ordonnance ord = snapshot.data!;
          return TextButton.icon(
            onPressed: () {
              // Logique pour afficher l'ordonnance (détails)
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E293B),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Détails de l\'ordonnance',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('Médicaments : ${ord.medicaments}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('Posologie : ${ord.posologie}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('Durée : ${ord.duree}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text('Voir l\'ordonnance'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlueLight,
              backgroundColor: AppTheme.primaryBlueLight.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
