import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme.dart';

// ─── Platform channel for foreground service ────────────────────────────────
const _serviceChannel = MethodChannel('com.codespace.mobile/service');

Future<void> _startBgService() async {
  try { await _serviceChannel.invokeMethod('startService'); } catch (_) {}
}
Future<void> _stopBgService() async {
  try { await _serviceChannel.invokeMethod('stopService'); } catch (_) {}
}

// ─── VS Code mobile CSS ──────────────────────────────────────────────────────
const _vscodeCss = r"""
/* ── Codespace Mobile patch v1.2 ── */

/* Activity bar: always hidden */
.part.activitybar,
.monaco-workbench .activitybar {
  display: none !important;
  width: 0 !important;
  min-width: 0 !important;
}

/* Sidebar: hidden by default, shown via body.cm-sidebar-on */
body:not(.cm-sidebar-on) .part.sidebar {
  display: none !important;
  width: 0 !important;
}
body.cm-sidebar-on .part.sidebar {
  display: flex !important;
  width: 260px !important;
  min-width: 260px !important;
  position: relative !important;
  z-index: 50 !important;
}

/* Editor fills screen */
body:not(.cm-sidebar-on) .part.editor,
body:not(.cm-sidebar-on) .monaco-workbench .part.editor {
  left: 0 !important;
  width: 100vw !important;
}
body.cm-sidebar-on .part.editor {
  left: 260px !important;
  width: calc(100vw - 260px) !important;
}

/* Bigger tabs */
.tabs-and-actions-container { height: 46px !important; }
.tabs-container .tab { height: 46px !important; padding: 0 14px !important; }
.tab-label { font-size: 13px !important; }

/* Status bar */
.part.statusbar { height: 30px !important; }
.statusbar-item a, .statusbar-item { font-size: 11px !important; }

/* Touch-friendly scrolling */
.monaco-scrollable-element { -webkit-overflow-scrolling: touch !important; }

/* Fix pointer events for overlays / dropdowns / quick-pick */
.quick-input-widget,
.monaco-quick-input-widget,
.quick-input-list,
.quick-input-list .monaco-list-row,
.context-menu,
.context-view,
.action-item,
.menubar-menu-button,
.monaco-dropdown,
.dropdown,
.dropdown-menu,
.select-container,
.select-container select,
.monaco-select-box,
.notification-toast,
.notifications-toasts,
.dialog-box,
.dialog-shadow,
.monaco-dialog-box {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  -webkit-tap-highlight-color: rgba(47,129,247,0.15) !important;
}

/* Copilot chat panel */
.chat-widget,
.inline-chat-widget,
.interactive-session,
.chat-input-part {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 100 !important;
}

/* Terminal */
.part.panel { min-height: 180px !important; }
.xterm { font-size: 13px !important; }
.xterm-viewport { touch-action: pan-y !important; }
""";

// ─── JS: CSS + MutationObserver + touch bridge + heartbeat + auto-reconnect ──
String _buildVscodeJs() => r"""
(function() {
  'use strict';
  if (window.__cmPatchInstalled) return;
  window.__cmPatchInstalled = true;

  // ── 1. CSS injection ──────────────────────────────────────────────────────
  var CSS = `""" + _vscodeCss.replaceAll('`', r'\`') + r"""`;

  function injectCss() {
    var el = document.getElementById('cm-patch-v4');
    if (!el) {
      el = document.createElement('style');
      el.id = 'cm-patch-v4';
      (document.head || document.documentElement).appendChild(el);
    }
    el.textContent = CSS;
  }

  injectCss();

  new MutationObserver(injectCss).observe(
    document.documentElement, { childList: true, subtree: false }
  );

  var t = 0;
  var cssIv = setInterval(function() {
    injectCss();
    if (++t > 30) clearInterval(cssIv);
  }, 1000);

  // ── 2. Viewport ───────────────────────────────────────────────────────────
  var meta = document.querySelector('meta[name=viewport]');
  if (!meta) {
    meta = document.createElement('meta');
    meta.name = 'viewport';
    document.head.appendChild(meta);
  }
  meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';

  // ── 3. Touch → Mouse event bridge ────────────────────────────────────────
  function synthesize(type, touch, target) {
    var evt = new MouseEvent(type, {
      bubbles: true, cancelable: true,
      view: window, detail: 1,
      screenX: touch.screenX, screenY: touch.screenY,
      clientX: touch.clientX, clientY: touch.clientY,
      button: 0, buttons: type === 'mousedown' ? 1 : 0
    });
    target.dispatchEvent(evt);
  }

  var INTERACTIVE = [
    '.quick-input-widget', '.context-menu', '.context-view',
    '.monaco-dropdown', '.dropdown-menu', '.select-container',
    '.monaco-list-row', '.action-item', '.menubar-menu-button',
    '.chat-widget', '.interactive-session .chat-input-part button',
    '.codicon', '.monaco-icon-label', '.quick-input-action',
    '[role="option"]', '[role="menuitem"]', '[role="button"]',
    '.suggest-widget', '.parameter-hints-widget'
  ].join(',');

  document.addEventListener('touchstart', function(e) {
    var el = e.target;
    if (el.closest && el.closest(INTERACTIVE)) {
      var tc = e.touches[0];
      synthesize('mouseover', tc, el);
      synthesize('mouseenter', tc, el);
      synthesize('mousedown', tc, el);
    }
  }, { passive: true });

  document.addEventListener('touchend', function(e) {
    var el = e.target;
    if (el.closest && el.closest(INTERACTIVE)) {
      var tc = e.changedTouches[0];
      synthesize('mouseup', tc, el);
      synthesize('click',   tc, el);
    }
  }, { passive: true });

  // Fix <select> elements (model picker)
  function patchSelects() {
    document.querySelectorAll('select').forEach(function(s) {
      s.style.pointerEvents = 'auto';
      s.style.touchAction = 'manipulation';
    });
  }
  patchSelects();
  new MutationObserver(patchSelects).observe(
    document.body || document.documentElement, { childList: true, subtree: true }
  );

  // ── 4. Heartbeat — keeps WebSocket alive every 20s ───────────────────────
  // Strategy: fetch a tiny resource from github.com so the radio stays active.
  // Even if it fails, it prevents the system from assuming the connection is idle.
  function heartbeat() {
    try {
      fetch('https://github.com/favicon.ico', {
        mode: 'no-cors', cache: 'no-store',
        signal: AbortSignal.timeout(5000)
      }).catch(function() {});
    } catch(_) {}
  }
  heartbeat();
  var heartbeatTimer = setInterval(heartbeat, 20000);

  // ── 5. Auto-reconnect on visibility restore ───────────────────────────────
  // When the user returns to the app after backgrounding, VS Code sometimes
  // shows "offline". We detect this and auto-click the reconnect button,
  // or reload as a last resort.
  var _wasHidden = false;

  function tryReconnect() {
    // VS Code shows a reload button — click it automatically
    var btn = document.querySelector(
      '.reload-window, [class*="reload"], [aria-label*="Reload"], ' +
      '[title*="Reload"], .messageActions .monaco-button'
    );
    if (btn) { btn.click(); return; }

    // GitHub Codespaces "offline" error page
    var offlineEl = document.querySelector(
      '[data-testid="offline-error"], .offline-error, ' +
      'button[data-action="reconnect"], [aria-label*="Reconnect"]'
    );
    if (offlineEl) { offlineEl.click(); return; }

    // Last resort: if URL still points to a codespace, do a soft reload
    if (window.location.href.includes('.github.dev') ||
        window.location.href.includes('vscode.dev')) {
      window.location.reload();
    }
  }

  document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
      _wasHidden = true;
    } else if (_wasHidden) {
      _wasHidden = false;
      // Small delay so VS Code has time to detect reconnect state
      setTimeout(tryReconnect, 1500);
      setTimeout(tryReconnect, 4000);
      heartbeat();
    }
  });

  // ── 6. Web Locks API — prevent background throttling ─────────────────────
  if (navigator.locks && navigator.locks.request) {
    navigator.locks.request(
      'cm_keepalive',
      { mode: 'shared' },
      function(lock) {
        return new Promise(function() {}); // never resolves → lock held forever
      }
    );
  }

})();
""";

// ─── JS: toggle sidebar ──────────────────────────────────────────────────────
const _toggleSidebarJs = r"""
(function() { document.body.classList.toggle('cm-sidebar-on'); })();
""";

// ────────────────────────────────────────────────────────────────────────────

class ViewerScreen extends StatefulWidget {
  final String initialUrl;
  const ViewerScreen({super.key, required this.initialUrl});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen>
    with WidgetsBindingObserver {
  late WebViewController _wvc;
  bool _loading = true;
  int _progress = 0;
  String _title = 'Codespaces';
  bool _isVSCode = false;
  bool _sidebarOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _buildWebView();
  }

  void _buildWebView() {
    _wvc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.bg)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => setState(() {
          _loading = true;
          _sidebarOn = false;
          _isVSCode = _isVSCodeUrl(url);
          _title = _titleFrom(url);
        }),
        onProgress: (p) => setState(() => _progress = p),
        onPageFinished: (url) async {
          setState(() {
            _loading = false;
            _isVSCode = _isVSCodeUrl(url);
            _title = _titleFrom(url);
          });
          if (_isVSCode) {
            // Inject immediately + after VS Code finishes lazy loading
            await _wvc.runJavaScript(_buildVscodeJs());
            await Future.delayed(const Duration(seconds: 2));
            await _wvc.runJavaScript(_buildVscodeJs());
            await Future.delayed(const Duration(seconds: 5));
            await _wvc.runJavaScript(_buildVscodeJs());
            _startBgService();
          }
        },
        onNavigationRequest: (_) => NavigationDecision.navigate,
        onWebResourceError: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Service + WakeLock handle background — nothing to do here
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopBgService();
    super.dispose();
  }

  bool _isVSCodeUrl(String url) =>
      url.contains('.github.dev') ||
      url.contains('vscode.dev') ||
      url.contains('.online.visualstudio.com');

  String _titleFrom(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'GitHub';
    if (_isVSCodeUrl(url)) {
      final name = uri.host.split('.').first;
      final parts = name.split('-');
      return parts.length >= 2 ? '${parts[0]}/${parts[1]}' : name;
    }
    if (uri.path.startsWith('/codespaces')) return 'Codespaces';
    if (uri.host == 'github.com') return 'GitHub';
    return uri.host;
  }

  Future<void> _toggleSidebar() async {
    await _wvc.runJavaScript(_toggleSidebarJs);
    setState(() => _sidebarOn = !_sidebarOn);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _wvc.canGoBack()) {
          _wvc.goBack();
        } else {
          _stopBgService();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: _buildBar(),
        body: Stack(children: [
          WebViewWidget(controller: _wvc),
          if (_loading)
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress / 100 : null,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                minHeight: 3,
              ),
            ),
        ]),
      ),
    );
  }

  PreferredSizeWidget _buildBar() {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppTheme.muted,
        onPressed: () async {
          if (await _wvc.canGoBack()) {
            _wvc.goBack();
          } else {
            _stopBgService();
            Navigator.of(context).pop();
          }
        },
      ),
      title: Row(children: [
        if (_isVSCode) ...[
          Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.green, shape: BoxShape.circle),
          ),
        ],
        Expanded(
          child: Text(
            _title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _isVSCode ? AppTheme.text : AppTheme.textSub,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
      actions: [
        if (_isVSCode) ...[
          _barBtn(
            _sidebarOn ? Icons.view_sidebar : Icons.view_sidebar_outlined,
            _sidebarOn ? AppTheme.accent : AppTheme.muted,
            _toggleSidebar,
          ),
        ],
        _barBtn(
          Icons.refresh_rounded,
          AppTheme.muted,
          () {
            setState(() => _loading = true);
            _wvc.reload();
          },
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
    );
  }

  Widget _barBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 21, color: color),
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
