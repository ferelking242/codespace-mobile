// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../theme.dart';

class ViewerScreen extends StatelessWidget {
  final String initialUrl;
  const ViewerScreen({super.key, required this.initialUrl});

  void _openUrl(String url) {
    js.context.callMethod('open', [url, '_blank']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.18),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.terminal_rounded,
                        size: 38, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Codespace Mobile',
                    style: TextStyle(
                      color: AppTheme.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'GitHub Copilot in your pocket',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 14,
                      letterSpacing: 0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Open Codespaces CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ouvrir GitHub Codespaces'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentDim,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _openUrl('https://github.com/codespaces'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Download APK
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.android_rounded, size: 18),
                      label: const Text('Télécharger APK Android'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.text,
                        side: const BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _openUrl(
                          'https://github.com/ferelking242/codespace-mobile/actions'),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Feature chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: const [
                      _Chip('🤖 GitHub Copilot'),
                      _Chip('💅 CSS Mobile'),
                      _Chip('🔐 Auth GitHub'),
                      _Chip('🌐 WebView optimisé'),
                      _Chip('📱 Touch → Mouse'),
                      _Chip('⚡ Agent Mode'),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Version web — Pour l\'expérience complète,\ninstalle l\'APK sur Android.',
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSub,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
