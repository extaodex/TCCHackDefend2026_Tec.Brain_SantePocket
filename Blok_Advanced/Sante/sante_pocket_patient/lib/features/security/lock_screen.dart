import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/bio_auth_service.dart';
import '../../core/security/security_service.dart';

class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticated = false;
  bool _isChecking = true;
  bool _usePasswordFallback = false;
  bool _hasStoredPassword = false;
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final hasPassword = await SecurityService.hasUserPassword();
    setState(() {
      _hasStoredPassword = hasPassword;
    });
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final canAuth = await BioAuthService.canAuthenticate();
    if (!canAuth) {
      setState(() {
        _usePasswordFallback = true;
        _isChecking = false;
      });
      return;
    }

    try {
      final success = await BioAuthService.authenticate();
      if (success) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      } else {
        setState(() {
          _usePasswordFallback = true;
          _isChecking = false;
        });
      }
    } catch (e) {
      setState(() {
        _usePasswordFallback = true;
        _isChecking = false;
      });
    }
  }

  Future<void> _handlePasswordSubmit() async {
    final pass = _passwordController.text.trim();
    if (pass.isEmpty) return;

    if (_hasStoredPassword) {
      final success = await SecurityService.verifyPassword(pass);
      if (success) {
        setState(() => _isAuthenticated = true);
      } else {
        setState(() => _errorMessage = "Mot de passe incorrect");
      }
    } else {
      // Premier paramétrage
      await SecurityService.setUserPassword(pass);
      setState(() => _isAuthenticated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueLight.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _usePasswordFallback ? Icons.password_rounded : Icons.lock_person_rounded,
                        color: AppTheme.primaryBlueLight,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Santé Pocket est verrouillé',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _usePasswordFallback 
                        ? (_hasStoredPassword ? 'Entrez votre mot de passe' : 'Définissez un mot de passe de secours')
                        : 'Veuillez vous authentifier pour accéder à vos données',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, decoration: TextDecoration.none, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Propulsé par Tec.Brain',
                      style: TextStyle(color: AppTheme.primaryBlueLight, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                    ),
                    const SizedBox(height: 32),
                    if (_isChecking)
                      const CircularProgressIndicator(color: AppTheme.primaryBlueLight)
                    else if (_usePasswordFallback)
                      Material( // Ajout de Material pour le TextField
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Mot de passe',
                                hintStyle: const TextStyle(color: Colors.white30),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                errorText: _errorMessage,
                              ),
                              onSubmitted: (_) => _handlePasswordSubmit(),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _handlePasswordSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlueLight,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(_hasStoredPassword ? 'Déverrouiller' : 'Enregistrer et Déverrouiller'),
                            ),
                            if (!_hasStoredPassword)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  "Note: Ce mot de passe sera demandé car votre appareil n'a pas de verrouillage système actif.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _checkAuth,
                              icon: const Icon(Icons.fingerprint_rounded),
                              label: const Text('Réessayer la biométrie'),
                              style: TextButton.styleFrom(foregroundColor: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _checkAuth,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Déverrouiller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlueLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
