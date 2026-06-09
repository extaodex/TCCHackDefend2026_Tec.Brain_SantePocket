import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import 'symptomes_provider.dart';

class SymptomesScreen extends ConsumerWidget {
  const SymptomesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomesAsync = ref.watch(symptomesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Journal des Symptômes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.orangeGradient),
        ),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.pendingOrangeLight,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Nouvelle note', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _showAddSymptomeDialog(context, ref),
      ),
      body: symptomesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.pendingOrangeLight)),
        error: (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: Colors.red))),
        data: (symptomes) {
          if (symptomes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.note_alt_rounded, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    const Text('Aucun symptôme enregistré',
                        style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Notez vos symptômes quotidiens pour un meilleur suivi médical.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white30, fontSize: 14)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: symptomes.length,
            itemBuilder: (context, index) {
              final s = symptomes[index];
              final isValide = s.statutValidation == 'VALIDE';
              final statusColor = isValide ? AppTheme.validatedGreenLight : AppTheme.pendingOrangeLight;
              final statusLabel = isValide ? 'Validé ✓' : 'En attente';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.white38),
                        const SizedBox(width: 6),
                        Text(s.date, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            if (s.id != null) {
                              ref.read(symptomesProvider.notifier).deleteSymptome(s.id!);
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(s.description,
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSymptomeDialog(BuildContext context, WidgetRef ref) {
    final descriptionController = TextEditingController();
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Nouveau Symptôme',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Décrivez vos symptômes...\nEx: Maux de tête persistants depuis ce matin, fatigue.',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pendingOrangeLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (descriptionController.text.isNotEmpty) {
                ref.read(symptomesProvider.notifier).addSymptome(
                  descriptionController.text,
                  dateStr,
                );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
