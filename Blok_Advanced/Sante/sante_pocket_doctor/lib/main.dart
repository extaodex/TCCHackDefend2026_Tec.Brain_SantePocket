import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_terminal/features/dashboard/dashboard_view.dart';
import 'package:desktop_terminal/features/consultation/consultation_view.dart';
import 'package:desktop_terminal/features/dashboard/patients_list_view.dart';
import 'package:desktop_terminal/features/dashboard/settings_view.dart';
import 'package:desktop_terminal/features/onboarding/onboarding_view.dart';
import 'package:desktop_terminal/core/services/user_profile_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFirstLaunch = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final firstLaunch = await UserProfileService.isFirstLaunch();
    setState(() {
      _isFirstLaunch = firstLaunch;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Santé Pocket - Terminal Médecin (Tec.Brain)',
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
      home: _isFirstLaunch
          ? OnboardingView(
              onOnboardingComplete: () {
                setState(() {
                  _isFirstLaunch = false;
                });
              },
            )
          : const MainLayout(),
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
  String _doctorName = 'Dr. Tcha';
  String _initials = 'DT';

  final List<Widget> _views = const [
    DashboardView(),
    PatientsListView(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  Future<void> _loadDoctorName() async {
    final name = await UserProfileService.getDoctorName() ?? 'Dr. Tcha';
    // Extraire les initiales
    final cleanName = name.replaceAll('Dr.', '').replaceAll('Dr', '').trim();
    final parts = cleanName.split(' ');
    String initials = 'DT';
    if (parts.isNotEmpty) {
      if (parts.length > 1) {
        initials = (parts[0].isNotEmpty ? parts[0][0] : '') + (parts[1].isNotEmpty ? parts[1][0] : '');
      } else {
        initials = parts[0].isNotEmpty ? parts[0].substring(0, parts[0].length > 1 ? 2 : 1) : 'DT';
      }
    }
    if (mounted) {
      setState(() {
        _doctorName = name;
        _initials = initials.toUpperCase();
      });
    }
  }

  void navigateToReception() {
    _onTabSelected(1); // Redirige vers la liste des patients
  }

  void navigateToPatients() {
    _onTabSelected(1);
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    _loadDoctorName(); // Rafraîchit le profil médecin en changeant de vue
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
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(10, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          // Logo & Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Santé', 
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 22, 
                            height: 1.1,
                            letterSpacing: -0.5,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('PRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const Text('Pocket Terminal', 
                      style: TextStyle(
                        fontWeight: FontWeight.w300, 
                        fontSize: 14, 
                        height: 1.1,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          // Navigation Items
          _sidebarItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Tableau de bord'),
          _sidebarItem(1, Icons.folder_shared_outlined, Icons.folder_shared, 'Dossiers Patients'),
          
          const Spacer(),
          
          _sidebarItem(2, Icons.settings_outlined, Icons.settings, 'Paramètres'),
          const SizedBox(height: 24),
          
          // Doctor Profile info
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondaryContainer],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(_initials, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_doctorName, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)), 
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text('Généraliste', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(
              colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
