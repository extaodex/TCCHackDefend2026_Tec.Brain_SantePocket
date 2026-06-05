import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/services/desktop_secure_transfer_service.dart';
import '../../core/services/database_service.dart';
import '../consultation/consultation_view.dart';
import '../../main.dart'; // Import to access MainLayout

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  int _todayCount = 0;
  int _totalCount = 0;
  String _doctorName = 'Dr. Dupont';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final today = await DatabaseService.getPatientCountToday();
    final total = await DatabaseService.getTotalPatientCount();
    final profile = await DatabaseService.getDoctorProfile();
    if (mounted) {
      setState(() {
        _todayCount = today;
        _totalCount = total;
        _doctorName = profile['name'] ?? 'Dr. Dupont';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(secureTransferServiceProvider);
    final service = ref.read(secureTransferServiceProvider.notifier);

    ref.listen(secureTransferServiceProvider, (previous, next) {
      if (next.status == ConnectionStatus.connected && next.patientRecord != null) {
        _refreshData(); // Refresh counts when a new record is received
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ConsultationView(patientRecord: next.patientRecord!)),
        );
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildStatsGrid(context),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildMainSyncCard(context, state, service),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildRecentActivity(context),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM yyyy', 'fr_FR').format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, $_doctorName',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 16),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Find MainLayout state and call navigateToReception
            final mainLayout = context.findAncestorStateOfType<MainLayoutState>();
            mainLayout?.navigateToReception();
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle Consultation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Patients du jour', '$_todayCount', Icons.people, Colors.blue)),
        const SizedBox(width: 24),
        Expanded(child: _buildStatCard(context, 'Total Dossiers', '$_totalCount', Icons.storage, Colors.teal)),
        const SizedBox(width: 24),
        Expanded(child: _buildStatCard(context, 'Alertes Critiques', '02', Icons.warning_amber_rounded, Colors.orange)),
        const SizedBox(width: 24),
        Expanded(child: _buildStatCard(context, 'Temps Moyen', '14 min', Icons.timer_outlined, Colors.purple)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSyncCard(BuildContext context, TransferState state, DesktopSecureTransferService service) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Réception Dossier Patient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text('Synchronisation sécurisée sans internet', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                _buildStatusBadge(state.status),
              ],
            ),
            const SizedBox(height: 48),
            if (state.status == ConnectionStatus.idle)
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 160,
                      width: 160,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha((0.05 * 255).toInt()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_tethering, size: 80, color: colorScheme.primary.withAlpha((0.5 * 255).toInt())),
                    ).animate(onPlay: (controller) => controller.repeat())
                     .scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                     .then()
                     .scale(duration: 1.seconds, begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
                    const SizedBox(height: 32),
                    const Text('Prêt à recevoir les données ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text('Le patient doit scanner le QR Code qui apparaîtra.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => service.startServer(),
                      icon: const Icon(Icons.power_settings_new),
                      label: const Text('ACTIVER LE TERMINAL'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            if (state.status == ConnectionStatus.listening)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Scanner pour envoyer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildStep(1, 'Connectez le patient au Wi-Fi "${state.localIp ?? 'Local'}"'),
                        _buildStep(2, 'Ouvrez l\'application Santé Pocket'),
                        _buildStep(3, 'Scannez le QR Code ci-contre'),
                        const SizedBox(height: 32),
                        OutlinedButton(
                          onPressed: () => service.stopServer(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text('Arrêter la réception'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.primary.withAlpha((0.1 * 255).toInt())),
                      boxShadow: [BoxShadow(color: colorScheme.primary.withAlpha((0.05 * 255).toInt()), blurRadius: 40)],
                    ),
                    child: QrImageView(
                      data: 'sante_sync:${state.localIp}:${state.port}',
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: colorScheme.primary),
                      dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: colorScheme.primary),
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: Colors.teal.shade50, child: Text('$number', style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ConnectionStatus status) {
    final (color, text) = switch (status) {
      ConnectionStatus.idle => (Colors.grey, 'INACTIF'),
      ConnectionStatus.listening => (Colors.green, 'À L\'ÉCOUTE'),
      ConnectionStatus.connected => (Colors.blue, 'CONNECTÉ'),
      ConnectionStatus.error => (Colors.red, 'ERREUR'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.5 * 255).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activités Récentes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            _activityItem('Dossier reçu - Marie Laurent', 'Il y a 10 min', Icons.download_done, Colors.green),
            _activityItem('Consultation terminée - Luc Simon', 'Il y a 45 min', Icons.check_circle_outline, Colors.blue),
            _activityItem('Alerte : Allergie détectée', 'Il y a 1h', Icons.warning_amber_rounded, Colors.orange),
            _activityItem('Export PDF généré', 'Il y a 2h', Icons.picture_as_pdf_outlined, Colors.red),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Voir tout l\'historique'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha((0.1 * 255).toInt()), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
