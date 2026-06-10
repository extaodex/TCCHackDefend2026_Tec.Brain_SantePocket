import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'vaccins_provider.dart';

class VaccinsScreen extends ConsumerWidget {
  const VaccinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccinsAsync = ref.watch(vaccinationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Carnet de Vaccination'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: vaccinsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.validatedGreenLight)),
        error: (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: Colors.red))),
        data: (vaccins) {
          if (vaccins.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vaccines_rounded, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 16),
                  const Text('Aucun vaccin enregistré',
                      style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('En attente du dossier médical envoyé par votre médecin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white30, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: vaccins.length,
            itemBuilder: (context, index) {
              final v = vaccins[index];
              final isValide = v.statutValidation == 'VALIDE';
              final statusColor = isValide ? AppTheme.validatedGreenLight : AppTheme.pendingOrangeLight;
              final statusLabel = isValide ? 'Validé ✓' : 'En attente';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.vaccines_rounded, color: statusColor, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.vaccin,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 13, color: Colors.white38),
                              const SizedBox(width: 4),
                              Text(v.date, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                              if (v.prochainRappel.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.notifications_active_rounded, size: 13, color: AppTheme.pendingOrangeLight),
                                const SizedBox(width: 4),
                                Text('Rappel: ${v.prochainRappel}',
                                    style: const TextStyle(color: AppTheme.pendingOrangeLight, fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(statusLabel,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
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
