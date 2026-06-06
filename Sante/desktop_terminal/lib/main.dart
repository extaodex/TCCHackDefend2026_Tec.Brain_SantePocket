import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_terminal/features/dashboard/dashboard_view.dart';
import 'package:desktop_terminal/features/consultation/consultation_view.dart';
import 'package:desktop_terminal/features/dashboard/patients_list_view.dart';
import 'package:desktop_terminal/features/dashboard/settings_view.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santé Pocket - Médecin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C), // Medical Teal
          primary: const Color(0xFF00695C),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1C1E)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _views = const [
    DashboardView(),
    // Will be updated to ReceptionView (the QR code scanner)
    ConsultationView(patientRecord: {}), 
    PatientsListView(),
    SettingsView(),
  ];

  void navigateToReception() {
    setState(() => _selectedIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildMedicalSidebar(),
          Expanded(
            child: _views[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSidebar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant.withAlpha((0.5 * 255).toInt()))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // Logo & Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.health_and_safety, color: colorScheme.primary, size: 32),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Santé', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.1)),
                        SizedBox(width: 4),
                        Text('• D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    Text('Pocket', style: TextStyle(fontWeight: FontWeight.w300, fontSize: 18, height: 1.1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Navigation Items
          _sidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Tableau de bord'),
          _sidebarItem(1, Icons.qr_code_scanner, Icons.qr_code_scanner, 'Réception'),
          _sidebarItem(2, Icons.folder_shared_outlined, Icons.folder_shared, 'Dossiers Patients'),
          
          const Spacer(),
          
          _sidebarItem(3, Icons.settings_outlined, Icons.settings, 'Paramètres'),
          
          // Doctor Profile info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha((0.05 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: const Text('JD', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. Dupont', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Généraliste', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : Colors.blueGrey,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
