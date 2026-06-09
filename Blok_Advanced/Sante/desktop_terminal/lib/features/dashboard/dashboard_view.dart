import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/services/desktop_secure_transfer_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/user_profile_service.dart';
import '../consultation/consultation_view.dart';
import '../../main.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  int _todayCount = 0;
  int _totalCount = 0;
  int _alertsCount = 0;
  List<Map<String, dynamic>> _recentPatients = [];
  String _doctorName = '';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final today = await DatabaseService.getPatientCountToday();
    final total = await DatabaseService.getTotalPatientCount();
    final alerts = await DatabaseService.getCriticalAlertsCount();
    final patients = await DatabaseService.getAllPatients();
    final name = await UserProfileService.getDoctorName() ?? 'Dr. Tcha';
    
    if (mounted) {
      setState(() {
        _todayCount = today;
        _totalCount = total;
        _alertsCount = alerts;
        _recentPatients = patients.take(4).toList();
        _doctorName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(secureTransferServiceProvider);
    final service = ref.read(secureTransferServiceProvider.notifier);

    // Navigation automatique vers ConsultationView si transfert réussi et dossier présent
    ref.listen(secureTransferServiceProvider, (previous, next) {
      if (next.status == FlowStatus.completed && next.patientRecord != null && next.flowType == FlowType.receiveFromPatient) {
        _refreshData();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ConsultationView(patientRecord: next.patientRecord!)),
        );
      } else if (next.status == FlowStatus.completed && next.flowType == FlowType.returnToPatient) {
        _refreshData();
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
              style: const TextStyle(
                fontSize: 34, 
                fontWeight: FontWeight.w900, 
                color: Color(0xFF1E293B),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              final mainLayout = context.findAncestorStateOfType<MainLayoutState>();
              mainLayout?.navigateToReception();
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('NOUVELLE CONSULTATION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'Consultations du jour', '$_todayCount', Icons.medical_services_outlined, const Color(0xFF3B82F6))),
        const SizedBox(width: 20),
        Expanded(child: _buildStatCard(context, 'Base Patients', '$_totalCount', Icons.badge_outlined, const Color(0xFF10B981))),
        const SizedBox(width: 20),
        Expanded(child: _buildStatCard(context, 'Alertes Critiques', '$_alertsCount', Icons.error_outline_rounded, const Color(0xFFEF4444))),
        const SizedBox(width: 20),
        Expanded(child: _buildStatCard(context, 'Disponibilité Réseau', 'Optimale', Icons.wifi_protected_setup_rounded, const Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(value, 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1E293B), letterSpacing: -1),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSyncCard(BuildContext context, TransferState state, DesktopSecureTransferService service) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastPatient = _recentPatients.isNotEmpty ? _recentPatients.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Background Accent
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Centre de Transfert Sécurisé', 
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1E293B), letterSpacing: -0.5),
                          ),
                          SizedBox(height: 4),
                          Text('Protocole P2P chiffré de bout en bout (AES-256)', 
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                          ),
                        ],
                      ),
                      _buildStatusBadge(state.status),
                    ],
                  ),
                  const SizedBox(height: 48),
                  if (state.status == FlowStatus.idle)
                    Column(
                      children: [
                        Center(
                          child: Container(
                            height: 160,
                            width: 160,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colorScheme.primary.withValues(alpha: 0.05), colorScheme.primary.withValues(alpha: 0.15)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(Icons.wifi_tethering_rounded, size: 80, color: colorScheme.primary)
                                .animate(onPlay: (controller) => controller.repeat())
                                .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.5))
                                .scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOut)
                                .then()
                                .scale(duration: 2.seconds, begin: const Offset(1.1, 1.1), end: const Offset(1, 1)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text('Prêt pour une nouvelle synchronisation', 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Colors.blueGrey),
                              SizedBox(width: 8),
                              Text('Assurez-vous que le patient a ouvert son application mobile.', 
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildActionButton(
                              context,
                              'RECEVOIR UN PATIENT',
                              'Import du dossier complet',
                              Icons.download_for_offline_rounded,
                              colorScheme.primary,
                              () => service.receiveFromPatient(),
                            ),
                            const SizedBox(width: 24),
                            _buildActionButton(
                              context,
                              'RETOURNER AU PATIENT',
                              'Envoi des notes & ordonnances',
                              Icons.upload_file_rounded,
                              const Color(0xFF6366F1),
                              lastPatient != null ? () => service.returnToPatient(lastPatient) : null,
                              isOutlined: true,
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    _buildProgressContent(context, state, service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback? onTap, {bool isOutlined = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade100 : (isOutlined ? Colors.white : color),
          borderRadius: BorderRadius.circular(20),
          border: isOutlined ? Border.all(color: color.withValues(alpha: 0.3), width: 2) : null,
          boxShadow: isOutlined || onTap == null ? [] : [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOutlined ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isOutlined ? color : Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, 
                    style: TextStyle(
                      color: isOutlined ? color : Colors.white, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(subtitle, 
                    style: TextStyle(
                      color: isOutlined ? Colors.blueGrey : Colors.white.withValues(alpha: 0.8), 
                      fontSize: 11,
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

  Widget _buildProgressContent(BuildContext context, TransferState state, DesktopSecureTransferService service) {
    final colorScheme = Theme.of(context).colorScheme;

    String message = "Traitement en cours...";
    bool showSpinner = true;
    bool showQr = false;
    bool showProgress = false;

    switch (state.status) {
      case FlowStatus.scanningWifi:
        message = "Recherche du patient par WiFi local...";
        break;
      case FlowStatus.connectingWifi:
        message = "Connexion au réseau temporaire du patient...";
        break;
      case FlowStatus.wifiConnected:
        message = "Connexion réseau établie.";
        break;
      case FlowStatus.discoveringDevice:
        message = "Identification de l'appareil mobile du patient...";
        break;
      case FlowStatus.deviceFound:
        message = "Appareil trouvé. Paire sécurisée établie avec ${state.pairedPatientName ?? 'le patient'}.";
        break;
      case FlowStatus.transferring:
        message = "Transfert chiffré AES-256 en cours...";
        showSpinner = false;
        showProgress = true;
        break;
      case FlowStatus.showingQrCode:
      case FlowStatus.waitingForConnection:
        message = "WiFi automatique non détecté. Veuillez scanner ce QR code depuis l'app mobile pour connecter et transférer.";
        showSpinner = false;
        showQr = true;
        break;
      case FlowStatus.completed:
        message = "Transfert sécurisé réussi !";
        showSpinner = false;
        break;
      case FlowStatus.error:
        message = "Erreur : ${state.errorMessage ?? 'Une erreur est survenue.'}";
        showSpinner = false;
        break;
      default:
        break;
    }

    return Column(
      children: [
        if (showSpinner) ...[
          const Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (showQr && state.qrCodeData != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: QrImageView(
                data: state.qrCodeData!,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (showProgress) ...[
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  if (state.currentTransferFilename != null) ...[
                    Text(
                      state.currentTransferFilename!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  LinearProgressIndicator(
                    value: state.transferProgress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${((state.transferProgress ?? 0.0) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: state.status == FlowStatus.error ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.status == FlowStatus.error || state.status == FlowStatus.completed)
              FilledButton(
                onPressed: () {
                  service.resetState();
                  _refreshData();
                },
                child: const Text('RETOUR AU TABLEAU DE BORD'),
              )
            else
              OutlinedButton.icon(
                onPressed: () => service.cancelTransfer(),
                icon: const Icon(Icons.close),
                label: const Text('ANNULER'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
          ],
        ),
      ],
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

  Widget _buildStatusBadge(FlowStatus status) {
    final (color, text) = switch (status) {
      FlowStatus.idle => (Colors.grey, 'INACTIF'),
      FlowStatus.scanningWifi => (Colors.orange, 'SCAN WIFI'),
      FlowStatus.connectingWifi => (Colors.orange, 'CONNEXION'),
      FlowStatus.wifiConnected => (Colors.blue, 'WIFI CONNECTÉ'),
      FlowStatus.discoveringDevice => (Colors.blue, 'DÉCOUVERTE'),
      FlowStatus.deviceFound => (Colors.green, 'PAIRE ÉTABLIE'),
      FlowStatus.transferring => (Colors.green, 'TRANSFERT'),
      FlowStatus.showingQrCode => (Colors.deepPurple, 'QR CODE'),
      FlowStatus.waitingForConnection => (Colors.deepPurple, 'QR EN ATTENTE'),
      FlowStatus.completed => (Colors.green, 'SUCCÈS'),
      FlowStatus.error => (Colors.red, 'ERREUR'),
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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activités Récentes', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
              Icon(Icons.history_toggle_off_rounded, color: Colors.blueGrey, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          if (_recentPatients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun dossier récent.',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._recentPatients.map((p) => _activityItem(
              '${p['nom']} ${p['prenom']}',
              'Dossier reçu le ${p['created_at'].split('T')[0]}',
              Icons.check_circle_outline_rounded,
              const Color(0xFF10B981),
            )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                final mainLayout = context.findAncestorStateOfType<MainLayoutState>();
                mainLayout?.navigateToPatients();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Voir tout l\'historique', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityItem(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
