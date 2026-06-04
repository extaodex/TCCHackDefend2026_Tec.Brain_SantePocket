import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/allergie.dart';
import '../../models/contact_urgence.dart';
import 'urgences_provider.dart';

class UrgencesScreen extends ConsumerWidget {
  const UrgencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Urgences & Allergies'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.redGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte alerte médicale
            _buildAlertCard(context),
            const SizedBox(height: 28),

            // Section Allergies
            _buildSectionHeader(context, 'Allergies Critiques', Icons.do_not_disturb_on_rounded,
                onAdd: () => _showAddAllergieDialog(context, ref)),
            const SizedBox(height: 12),
            _AllergiesList(),
            const SizedBox(height: 28),

            // Section Contacts d'urgence
            _buildSectionHeader(context, 'Contacts de Secours', Icons.contacts_rounded,
                onAdd: () => _showContactOptions(context, ref)),
            const SizedBox(height: 12),
            _ContactsList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.emergencyRedDark.withValues(alpha: 0.6),
            AppTheme.emergencyRedDark.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.emergencyRedLight.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.emergencyRedLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.health_and_safety_rounded,
                color: AppTheme.emergencyRedLight, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerte Médicale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                const SizedBox(height: 4),
                Text(
                  'Ces informations sont vitales en cas d\'urgence. Maintenez-les à jour.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon,
      {required VoidCallback onAdd}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.emergencyRedLight, size: 22),
        const SizedBox(width: 10),
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.emergencyRedLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.emergencyRedLight.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: AppTheme.emergencyRedLight, size: 18),
                const SizedBox(width: 4),
                Text('Ajouter',
                    style: TextStyle(
                        color: AppTheme.emergencyRedLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddAllergieDialog(BuildContext context, WidgetRef ref) {
    final libellController = TextEditingController();
    String selectedSeverite = 'Critique';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Nouvelle Allergie',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: libellController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex: Pénicilline, Arachides...',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: ['Critique', 'Modérée', 'Légère'].map((sev) {
                  final isSelected = selectedSeverite == sev;
                  final color = sev == 'Critique'
                      ? AppTheme.emergencyRedLight
                      : sev == 'Modérée'
                          ? Colors.orange
                          : Colors.green;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedSeverite = sev),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? color : Colors.white24),
                        ),
                        child: Text(sev,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: isSelected ? color : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
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
                  backgroundColor: AppTheme.emergencyRedLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (libellController.text.isNotEmpty) {
                  ref
                      .read(allergiesProvider.notifier)
                      .addAllergie(libellController.text, selectedSeverite);
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche les options : importer depuis les contacts OU saisie manuelle
  void _showContactOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Ajouter un contact de secours',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Option 1 : Importer depuis les contacts du téléphone
            _buildOptionTile(
              ctx,
              icon: Icons.contact_phone_rounded,
              color: AppTheme.primaryBlueLight,
              title: 'Importer depuis mes contacts',
              subtitle: 'Sélectionnez un ou plusieurs contacts',
              onTap: () {
                Navigator.of(ctx).pop();
                _importFromDeviceContacts(context, ref);
              },
            ),
            const SizedBox(height: 12),

            // Option 2 : Saisie manuelle
            _buildOptionTile(
              ctx,
              icon: Icons.edit_rounded,
              color: AppTheme.pendingOrangeLight,
              title: 'Saisie manuelle',
              subtitle: 'Entrez les informations manuellement',
              onTap: () {
                Navigator.of(ctx).pop();
                _showAddContactDialog(context, ref);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext ctx,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  /// Importe les contacts depuis le téléphone via flutter_contacts
  Future<void> _importFromDeviceContacts(BuildContext context, WidgetRef ref) async {
    // Demander la permission
    final hasPermission = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Permission d\'accès aux contacts refusée'),
            backgroundColor: AppTheme.emergencyRedLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Charger les contacts avec les numéros de téléphone
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    if (!context.mounted) return;

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucun contact trouvé sur l\'appareil'),
          backgroundColor: AppTheme.pendingOrangeLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Afficher le sélecteur multiple de contacts
    _showContactSelector(context, ref, contacts);
  }

  /// Affiche un bottom sheet pour sélectionner plusieurs contacts
  void _showContactSelector(BuildContext context, WidgetRef ref, List<Contact> deviceContacts) {
    // Filtrer les contacts ayant au moins un numéro de téléphone
    final contactsWithPhone = deviceContacts
        .where((c) => c.phones.isNotEmpty)
        .toList();

    final Set<int> selectedIndices = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.contacts_rounded, color: AppTheme.primaryBlueLight),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Sélectionnez vos contacts (${selectedIndices.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: contactsWithPhone.isEmpty
                        ? const Center(
                            child: Text('Aucun contact avec numéro de téléphone',
                                style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            itemCount: contactsWithPhone.length,
                            itemBuilder: (ctx, index) {
                              final contact = contactsWithPhone[index];
                              final isSelected = selectedIndices.contains(index);
                              final phone = contact.phones.first.number;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? AppTheme.validatedGreenLight.withValues(alpha: 0.2)
                                      : AppTheme.emergencyRedLight.withValues(alpha: 0.1),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded,
                                          color: AppTheme.validatedGreenLight)
                                      : Text(
                                          contact.displayName.isNotEmpty
                                              ? contact.displayName[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppTheme.emergencyRedLight,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                title: Text(contact.displayName,
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.validatedGreenLight : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    )),
                                subtitle: Text(phone,
                                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      selectedIndices.remove(index);
                                    } else {
                                      selectedIndices.add(index);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  // Bouton de validation
                  if (selectedIndices.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            for (final idx in selectedIndices) {
                              final contact = contactsWithPhone[idx];
                              final phone = contact.phones.first.number;
                              ref.read(contactsUrgenceProvider.notifier).addContact(
                                contact.displayName,
                                'Contact',
                                phone,
                              );
                            }
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '✅ ${selectedIndices.length} contact(s) ajouté(s) avec succès'),
                                backgroundColor: AppTheme.validatedGreenLight,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                          label: Text(
                            'Ajouter ${selectedIndices.length} contact(s)',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.validatedGreenLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddContactDialog(BuildContext context, WidgetRef ref) {
    final nomController = TextEditingController();
    final relationController = TextEditingController();
    final telController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Nouveau Contact',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(nomController, 'Nom complet', Icons.person_rounded),
            const SizedBox(height: 12),
            _buildDialogField(relationController, 'Relation (ex: Épouse, Dr.)', Icons.group_rounded),
            const SizedBox(height: 12),
            _buildDialogField(telController, 'Téléphone', Icons.phone_rounded,
                inputType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emergencyRedLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (nomController.text.isNotEmpty && telController.text.isNotEmpty) {
                ref.read(contactsUrgenceProvider.notifier).addContact(
                    nomController.text,
                    relationController.text.isEmpty ? 'Contact' : relationController.text,
                    telController.text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String hint, IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Widget liste des allergies
// ──────────────────────────────────────────────
class _AllergiesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allergiesAsync = ref.watch(allergiesProvider);
    return allergiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emergencyRedLight)),
      error: (e, _) => Text('Erreur : $e', style: const TextStyle(color: Colors.red)),
      data: (allergies) {
        if (allergies.isEmpty) {
          return _buildEmptyState('Aucune allergie enregistrée',
              'Appuyez sur "Ajouter" pour déclarer une allergie critique.');
        }
        return Column(
          children: allergies.map((a) => _AllergieCard(allergie: a)).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 40),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AllergieCard extends ConsumerWidget {
  final Allergie allergie;
  const _AllergieCard({required this.allergie});

  Color _severiteColor() {
    switch (allergie.severite) {
      case 'Critique':
        return AppTheme.emergencyRedLight;
      case 'Modérée':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _severiteColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.do_not_disturb_on_rounded, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(allergie.libelle,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(allergie.severite,
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              if (allergie.id != null) {
                ref.read(allergiesProvider.notifier).deleteAllergie(allergie.id!);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 20),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Widget liste des contacts d'urgence
// ──────────────────────────────────────────────
class _ContactsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsUrgenceProvider);
    return contactsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.emergencyRedLight)),
      error: (e, _) => Text('Erreur : $e', style: const TextStyle(color: Colors.red)),
      data: (contacts) {
        if (contacts.isEmpty) {
          return _buildEmptyState('Aucun contact de secours',
              'Ajoutez un proche ou votre médecin pour les situations d\'urgence.');
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: List.generate(contacts.length, (index) {
              final contact = contacts[index];
              return Column(
                children: [
                  _ContactTile(contact: contact),
                  if (index < contacts.length - 1)
                    Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_add_outlined, color: Colors.white38, size: 40),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ContactTile extends ConsumerWidget {
  final ContactUrgence contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.emergencyRedLight.withValues(alpha: 0.15),
            child: Text(
              contact.nom.isNotEmpty ? contact.nom[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.emergencyRedLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.nom,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(contact.relation,
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          // Bouton appel (lance l'appel immédiatement)
          IconButton(
            onPressed: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: contact.telephone.replaceAll(RegExp(r'\s+'), ''),
              );
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('⚠️ Impossible de lancer l\'appel'),
                      backgroundColor: AppTheme.emergencyRedLight,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.emergencyRedLight),
          ),
          IconButton(
            onPressed: () {
              if (contact.id != null) {
                ref.read(contactsUrgenceProvider.notifier).deleteContact(contact.id!);
              }
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 20),
          ),
        ],
      ),
    );
  }
}
