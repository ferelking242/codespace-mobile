import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme.dart';
import 'viewer_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late WebViewController _wvc;
  bool _loading = true;
  int _progress = 0;
  bool _webviewVisible = false;

  @override
  void initState() {
    super.initState();
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.bg)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onProgress: (p) => setState(() => _progress = p),
        onPageFinished: (url) {
          setState(() {
            _loading = false;
            _webviewVisible = true;
          });
          _checkLoggedIn(url);
        },
        onNavigationRequest: (_) => NavigationDecision.navigate,
      ))
      ..loadRequest(Uri.parse('https://github.com/login'));
  }

  Future<void> _checkLoggedIn(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final isGitHub = uri.host == 'github.com' || uri.host.endsWith('.github.com');
    final isAuthPage = uri.path.startsWith('/login') ||
        uri.path.startsWith('/session') ||
        uri.path.startsWith('/signup') ||
        uri.path.startsWith('/password_reset') ||
        uri.path.startsWith('/two-factor') ||
        uri.path.startsWith('/device');
    if (isGitHub && !isAuthPage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            const ViewerScreen(initialUrl: 'https://github.com/codespaces'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: AppTheme.surface,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.terminal_rounded,
                            size: 16, color: AppTheme.accent),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Sign in to GitHub',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  child: _loading
                      ? LinearProgressIndicator(
                          value: _progress > 0 ? _progress / 100 : null,
                          backgroundColor: Colors.transparent,
                          valueColor:
                              const AlwaysStoppedAnimation(AppTheme.accent),
                          minHeight: 2,
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: _webviewVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: WebViewWidget(controller: _wvc),
          ),
          if (!_webviewVisible)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent),
              ),
            ),
        ],
      ),
    );
  }
}
