import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme.dart';

// ─── Platform channel ────────────────────────────────────────────────────────
const _serviceChannel = MethodChannel('com.codespace.mobile/service');
Future<void> _startBgService() async {
  try { await _serviceChannel.invokeMethod('startService'); } catch (_) {}
}
Future<void> _stopBgService() async {
  try { await _serviceChannel.invokeMethod('stopService'); } catch (_) {}
}

// ─── VS Code mobile CSS ──────────────────────────────────────────────────────
// Règle d'or : ne PAS toucher overflow/flex sur split-view-view, Monaco gère.
const _vscodeCss = r"""
/* ══ Codespace Mobile v2.2 ══════════════════════════════════════════════════ */

/* ── Activity bar : caché ────────────────────────────────────────────────── */
.part.activitybar,
.monaco-workbench .activitybar {
  display: none !important;
  width: 0 !important;
  min-width: 0 !important;
}

/* ── Sidebar : cachée par défaut, visible via body.cm-sidebar-on ─────────── */
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

/* ── Éditeur : plein écran quand sidebar cachée ──────────────────────────── */
body:not(.cm-sidebar-on) .part.editor,
body:not(.cm-sidebar-on) .monaco-workbench .part.editor {
  left: 0 !important;
  width: 100vw !important;
}
body.cm-sidebar-on .part.editor {
  left: 260px !important;
  width: calc(100vw - 260px) !important;
}

/* ── Tabs : plus grandes pour les doigts ────────────────────────────────── */
.tabs-and-actions-container { height: 46px !important; }
.tabs-container .tab { height: 46px !important; padding: 0 14px !important; }
.tab-label { font-size: 13px !important; }
.tab-close-button { width: 28px !important; height: 28px !important; }

/* ── Barre de statut ─────────────────────────────────────────────────────── */
.part.statusbar { height: 28px !important; }
.statusbar-item a, .statusbar-item { font-size: 11px !important; }

/* ── Scroll tactile ──────────────────────────────────────────────────────── */
.monaco-scrollable-element { -webkit-overflow-scrolling: touch !important; }
.monaco-editor .overflow-guard { touch-action: pan-x pan-y !important; }

/* ── Terminal ────────────────────────────────────────────────────────────── */
.part.panel { min-height: 180px !important; }
.xterm { font-size: 13px !important; line-height: 1.4 !important; }
.xterm-viewport { touch-action: pan-y !important; overflow-y: auto !important; }
.xterm-screen canvas { touch-action: none !important; }

/* ── Pointer events sur tous les éléments interactifs ───────────────────── */
.quick-input-widget,
.monaco-quick-input-widget,
.quick-input-list,
.quick-input-list .monaco-list-row,
.context-menu,
.context-view,
.action-item,
.action-label,
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

/* ── Copilot / Chat / Agent ──────────────────────────────────────────────── */
.chat-widget,
.inline-chat-widget,
.interactive-session,
.chat-input-part,
.chat-list-item,
.chat-editing-session {
  pointer-events: auto !important;
  touch-action: manipulation !important;
}
.interactive-input-box .input { min-height: 48px !important; }
.monaco-dialog-box button { min-height: 36px !important; padding: 0 16px !important; }

/* ── Model picker (sélecteur IA Copilot) ─────────────────────────────────── */
[class*="modelPicker"],
[class*="model-picker"],
.chat-model-picker,
.model-picker,
[aria-label*="odel" i],
select,
select option {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  -webkit-tap-highlight-color: rgba(47,129,247,0.18) !important;
}

/* ── Suggestions / hints ─────────────────────────────────────────────────── */
.suggest-widget, .parameter-hints-widget {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
}
.suggest-widget .monaco-list-row { min-height: 36px !important; }

/* ── Rôles ARIA génériques ───────────────────────────────────────────────── */
[role="option"], [role="menuitem"], [role="button"], [role="tab"],
.codicon, .monaco-icon-label, .breadcrumb-item {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  -webkit-tap-highlight-color: rgba(47,129,247,0.15) !important;
}

/* ── Sélection de texte : seulement dans les zones de contenu ───────────── */
.monaco-workbench { -webkit-user-select: none !important; user-select: none !important; }
.monaco-editor, .xterm, .chat-widget, .interactive-session {
  -webkit-user-select: text !important; user-select: text !important;
}
""";

// ─── JS patch principal ───────────────────────────────────────────────────────
String _buildVscodeJs() => r"""
(function() {
  'use strict';
  if (window.__cmPatch22) return;
  window.__cmPatch22 = true;

  /* 1 ── Injection CSS ──────────────────────────────────────────────────── */
  var CSS = `""" + _vscodeCss.replaceAll('`', r'\`') + r"""`;

  function injectCss() {
    var el = document.getElementById('cm-patch-v8');
    if (!el) {
      el = document.createElement('style');
      el.id = 'cm-patch-v8';
      (document.head || document.documentElement).appendChild(el);
    }
    el.textContent = CSS;
  }

  injectCss();

  /* Observer peu profond pour réinjecter si <head> est rechargé */
  new MutationObserver(injectCss).observe(
    document.documentElement, { childList: true, subtree: false }
  );

  /* Réinjection pendant 60s pour les panneaux chargés en lazy */
  var _n = 0;
  var _iv = setInterval(function() { injectCss(); if (++_n >= 60) clearInterval(_iv); }, 1000);

  /* 2 ── Viewport ────────────────────────────────────────────────────────── */
  (function() {
    var m = document.querySelector('meta[name=viewport]');
    if (!m) { m = document.createElement('meta'); m.name = 'viewport';
      (document.head || document.documentElement).appendChild(m); }
    m.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
  })();

  /* 3 ── Touch → Mouse bridge ─────────────────────────────────────────────
     passive:true intentionnel — ne pas appeler preventDefault() ici,
     sinon on bloque les handlers touch natifs de VS Code (scroll, drag…).
     Le bridge envoie les events souris EN PLUS des events touch natifs.
  ── */
  function synth(type, touch, target) {
    target.dispatchEvent(new MouseEvent(type, {
      bubbles: true, cancelable: true, view: window, detail: 1,
      screenX: touch.screenX, screenY: touch.screenY,
      clientX: touch.clientX, clientY: touch.clientY,
      button: 0, buttons: type === 'mousedown' ? 1 : 0
    }));
  }

  var INTERACTIVE = [
    /* Overlays */
    '.quick-input-widget', '.context-menu', '.context-view',
    '.monaco-dropdown', '.dropdown-menu', '.select-container',
    /* Listes */
    '.monaco-list-row', '.monaco-tree-row',
    /* Boutons / actions */
    '.action-item', '.action-label', '.menubar-menu-button',
    '.toolbar-toggle-more', '.quick-input-action',
    /* Tabs */
    '.tab', '.tab-close-button', '.tabs-and-actions-container .action-item',
    /* Chat / Copilot / Agent */
    '.chat-widget', '.interactive-session .chat-input-part button',
    '.chat-execute-toolbar .action-item',
    '.inline-chat-widget .action-item',
    '.chat-editing-session .action-item',
    /* Model picker */
    '[class*="modelPicker"]', '[class*="model-picker"]',
    '.chat-model-picker', '.model-picker',
    /* Suggestions */
    '.suggest-widget .monaco-list-row', '.parameter-hints-widget',
    /* Notifications / dialogs */
    '.notification-list-item', '.monaco-dialog-box button',
    /* Rôles ARIA */
    '[role="option"]', '[role="menuitem"]', '[role="button"]', '[role="tab"]',
    /* Icônes */
    '.codicon', '.monaco-icon-label', '.breadcrumb-item'
  ].join(',');

  document.addEventListener('touchstart', function(e) {
    var el = e.target;
    var hit = el.closest && el.closest(INTERACTIVE);
    if (!hit) return;
    var t = e.touches[0];
    synth('mouseover',  t, hit);
    synth('mouseenter', t, hit);
    synth('mousedown',  t, hit);
  }, { passive: true });

  document.addEventListener('touchend', function(e) {
    var el = e.target;
    var hit = el.closest && el.closest(INTERACTIVE);
    if (!hit) return;
    var t = e.changedTouches[0];
    synth('mouseup',    t, hit);
    synth('click',      t, hit);
    synth('mouseleave', t, hit);
  }, { passive: true });

  /* 4 ── Patch <select> natif (model picker) ──────────────────────────────
     Fire aussi 'input' pour que VS Code détecte le changement de modèle.
  ── */
  function patchSelects() {
    document.querySelectorAll('select').forEach(function(s) {
      if (s.__cmPatched) return;
      s.__cmPatched = true;
      s.style.pointerEvents = 'auto';
      s.style.touchAction = 'manipulation';
      s.addEventListener('change', function() {
        s.dispatchEvent(new Event('input', { bubbles: true }));
      });
    });
  }
  patchSelects();
  new MutationObserver(patchSelects).observe(
    document.documentElement, { childList: true, subtree: true }
  );

  /* 5 ── Heartbeat : garde le WebSocket + radio WiFi actifs ───────────────── */
  function heartbeat() {
    try {
      fetch('https://github.com/favicon.ico', {
        mode: 'no-cors', cache: 'no-store',
        signal: AbortSignal.timeout(5000)
      }).catch(function(){});
    } catch(_){}
  }
  heartbeat();
  setInterval(heartbeat, 20000);

  /* 6 ── Auto-reconnect au retour foreground ──────────────────────────────── */
  var _wasHidden = false;
  document.addEventListener('visibilitychange', function() {
    if (document.hidden) { _wasHidden = true; return; }
    if (!_wasHidden) return;
    _wasHidden = false;
    heartbeat();
    setTimeout(function() {
      var btn = document.querySelector(
        '.reload-window, [class*="reload"][class*="button"], ' +
        '[aria-label*="Reload Window"], button[data-action="reconnect"], ' +
        '[aria-label*="Reconnect"], [title*="Reload"]'
      );
      if (btn) { btn.click(); return; }
      var offline = document.querySelector('[data-testid="offline-error"] button');
      if (offline) { offline.click(); return; }
      var h = window.location.href;
      if (h.includes('.github.dev') || h.includes('vscode.dev')) window.location.reload();
    }, 1500);
    setTimeout(heartbeat, 4000);
  });

  /* 7 ── Web Locks : empêche le throttling JS en arrière-plan ─────────────── */
  if (navigator.locks && navigator.locks.request) {
    navigator.locks.request('cm_keepalive', { mode: 'shared' }, function() {
      return new Promise(function() {});
    });
  }

})();
""";

// ─── Toggle sidebar (classe cm-sidebar-on sur body) ──────────────────────────
const _toggleSidebarJs = r"""
(function() { document.body.classList.toggle('cm-sidebar-on'); })();
""";

// ─────────────────────────────────────────────────────────────────────────────

class ViewerScreen extends StatefulWidget {
  final String initialUrl;
  const ViewerScreen({super.key, required this.initialUrl});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen>
    with WidgetsBindingObserver {
  late WebViewController _wvc;
  bool _loading  = true;
  int  _progress = 0;
  String _title  = 'Codespaces';
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
        'Mozilla/5.0 (Linux; Android 14; Pixel 9) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => setState(() {
          _loading   = true;
          _sidebarOn = false;
          _isVSCode  = _isVSCodeUrl(url);
          _title     = _titleFrom(url);
        }),
        onProgress: (p) => setState(() => _progress = p),
        onPageFinished: (url) async {
          setState(() {
            _loading  = false;
            _isVSCode = _isVSCodeUrl(url);
            _title    = _titleFrom(url);
          });
          if (_isVSCode) {
            // Injection immédiate + 2 s + 5 s (pour panneaux lazy-loadés)
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
  void didChangeAppLifecycleState(AppLifecycleState state) {}

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
      final parts = uri.host.split('.').first.split('-');
      return parts.length >= 2 ? '${parts[0]}/${parts[1]}' : uri.host.split('.').first;
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
