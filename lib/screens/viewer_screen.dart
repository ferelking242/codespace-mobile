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

// ─── CSS ─────────────────────────────────────────────────────────────────────
// NOTE: All !important rules are intentional — VS Code web injects its own
// inline styles and we must override them unconditionally.
// IMPORTANT: These rules must ONLY be applied after the monaco-workbench is
// fully ready. Injecting during "Setting up your workspace" breaks VS Code's
// layout initialisation and causes the page to hang indefinitely.
const _vscodeCss = r"""
/* ══ Codespace Mobile v1.4 ═════════════════════════════════════════════════ */

/* NOTE: No :root CSS-variable overrides here — VS Code reads those variables
   during workbench boot and zeroing them during setup causes a layout deadlock
   that leaves the page stuck on "Setting up your workspace". */

/* ── Activity bar: hide once workbench is ready ─────────────────────────── */
/* Scoped to .monaco-workbench so rules are inert before the workbench mounts */
.monaco-workbench .part.activitybar,
.monaco-workbench .activitybar.part,
.monaco-workbench > .part.activitybar,
.monaco-workbench div.part.activitybar,
.monaco-workbench [class*="activitybar"][class*="part"],
.monaco-workbench .activityBarContent,
.monaco-workbench .activity-bar {
  display: none !important;
  width: 0 !important;
  min-width: 0 !important;
  max-width: 0 !important;
  overflow: hidden !important;
  opacity: 0 !important;
  pointer-events: none !important;
  flex: 0 0 0 !important;
  position: absolute !important;
  left: -9999px !important;
}

/* ── Secondary sidebar (Copilot chat panel) toggle ──────────────────────── */
body:not(.cm-copilot-on) .part.auxiliarybar,
body:not(.cm-copilot-on) .auxiliary-bar,
body:not(.cm-copilot-on) [class*="auxiliarybar"] {
  display: none !important;
  width: 0 !important;
  max-width: 0 !important;
  overflow: hidden !important;
  flex: 0 0 0 !important;
}
body.cm-copilot-on .part.auxiliarybar,
body.cm-copilot-on .auxiliary-bar {
  display: flex !important;
  width: 320px !important;
  min-width: 280px !important;
  max-width: 320px !important;
  position: relative !important;
  z-index: 50 !important;
  overflow: hidden !important;
}

/* ── Left sidebar (file tree) ───────────────────────────────────────────── */
body:not(.cm-sidebar-on) .part.sidebar,
body:not(.cm-sidebar-on) .sidebar.part {
  display: none !important;
  width: 0 !important;
  min-width: 0 !important;
  max-width: 0 !important;
  overflow: hidden !important;
  flex: 0 0 0 !important;
}
body.cm-sidebar-on .part.sidebar {
  display: flex !important;
  width: 240px !important;
  min-width: 240px !important;
  max-width: 240px !important;
  position: relative !important;
  z-index: 50 !important;
  overflow: hidden !important;
}

/* ── Editor: always fills remaining width ───────────────────────────────── */
.part.editor,
.monaco-workbench .part.editor,
.editor-container,
.editorContainer {
  flex: 1 1 auto !important;
  width: auto !important;
  min-width: 0 !important;
  left: 0 !important;
}

/* ── Workbench: force full-width horizontal flex ────────────────────────── */
.monaco-workbench .monaco-grid-view,
.monaco-workbench .monaco-grid-branch-node,
.monaco-workbench .split-view-view {
  overflow: visible !important;
}

/* ── VS Code top toolbar (breadcrumbs / nav bar) ─────────────────────────── */
.editor-toolbar,
.breadcrumbs-control,
.title.tabs-container ~ .toolbar,
.editor-group-container .title .title-label { font-size: 12px !important; }

/* ── Bigger tabs for touch ───────────────────────────────────────────────── */
.tabs-and-actions-container,
.monaco-workbench .part.editor .tabs-and-actions-container {
  height: 44px !important;
  min-height: 44px !important;
}
.tabs-container .tab { height: 44px !important; padding: 0 12px !important; }
.tab-label { font-size: 13px !important; }

/* ── Status bar ──────────────────────────────────────────────────────────── */
.part.statusbar {
  height: 26px !important;
  min-height: 26px !important;
}
.statusbar-item a, .statusbar-item { font-size: 11px !important; }

/* ── Terminal panel ──────────────────────────────────────────────────────── */
.part.panel { min-height: 160px !important; }
.xterm { font-size: 13px !important; }
.xterm-viewport { touch-action: pan-y !important; }
.xterm-screen canvas { touch-action: none !important; }

/* ── Touch-friendly scrolling ────────────────────────────────────────────── */
.monaco-scrollable-element {
  -webkit-overflow-scrolling: touch !important;
}

/* ── Pointer events: overlays, quick-pick, model picker ─────────────────── */
.quick-input-widget, .monaco-quick-input-widget,
.quick-input-list, .quick-input-list .monaco-list-row,
.context-menu, .context-view,
.action-item, .menubar-menu-button,
.monaco-dropdown, .dropdown, .dropdown-menu,
.select-container, .select-container select, .monaco-select-box,
.notification-toast, .notifications-toasts,
.dialog-box, .dialog-shadow, .monaco-dialog-box,
.suggest-widget, .parameter-hints-widget,
[role="option"], [role="menuitem"], [role="listbox"] {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  -webkit-tap-highlight-color: rgba(47,129,247,0.18) !important;
  z-index: 2000 !important;
}

/* ── Copilot chat ────────────────────────────────────────────────────────── */
.chat-widget, .inline-chat-widget,
.interactive-session, .chat-input-part,
.chat-list-item { pointer-events: auto !important; touch-action: manipulation !important; }

/* ── Quick-pick items: larger hit targets ────────────────────────────────── */
.quick-input-list .monaco-list-row {
  min-height: 40px !important;
  line-height: 40px !important;
}

/* ── Copilot chat input: auto height ─────────────────────────────────────── */
.interactive-input-box .input { min-height: 48px !important; }
""";

// ─── Main VS Code JS patch ───────────────────────────────────────────────────
String _buildVscodeJs() => r"""
(function() {
  'use strict';
  if (window.__cmPatch14) return;
  window.__cmPatch14 = true;

  /* 1 ── CSS injection ───────────────────────────────────────────────────── */
  var CSS = `""" + _vscodeCss.replaceAll('`', r'\`') + r"""`;

  function injectCss() {
    var el = document.getElementById('cm-patch-v5');
    if (!el) {
      el = document.createElement('style');
      el.id = 'cm-patch-v5';
      document.head
        ? document.head.appendChild(el)
        : document.documentElement.appendChild(el);
    }
    el.textContent = CSS;
  }

  /* ── Workbench-ready gate ───────────────────────────────────────────────
     NEVER inject CSS before .monaco-workbench exists. Injecting during the
     "Setting up your workspace" phase overrides VS Code's CSS variables and
     causes the workbench layout engine to deadlock, leaving the page stuck.
  ── */
  function isWorkbenchReady() {
    return !!document.querySelector('.monaco-workbench');
  }

  /* Debounced re-inject: coalesces rapid mutation bursts into one call */
  var _debTimer = null;
  function debouncedInject() {
    if (!isWorkbenchReady()) return;
    clearTimeout(_debTimer);
    _debTimer = setTimeout(function() {
      injectCss();
      /* Force-remove activity bar inline style if VS Code re-adds width */
      document.querySelectorAll('.monaco-workbench .part.activitybar, .monaco-workbench .activitybar.part').forEach(function(node) {
        node.style.setProperty('display', 'none', 'important');
        node.style.setProperty('width', '0', 'important');
        node.style.setProperty('max-width', '0', 'important');
      });
    }, 150);
  }

  /* Poll for workbench ready, then inject once and start the observer */
  var _readyPoll = setInterval(function() {
    if (!isWorkbenchReady()) return;
    clearInterval(_readyPoll);
    injectCss();

    /* Re-inject when VS Code rebuilds the DOM — debounced to avoid cascade */
    new MutationObserver(debouncedInject)
      .observe(document.documentElement, {
        childList: true, subtree: true,
        attributes: true, attributeFilter: ['style', 'class']
      });

    /* Retry for 30s after workbench ready (lazy-loaded components) */
    var t = 0;
    var cssIv = setInterval(function() {
      injectCss();
      if (++t > 30) clearInterval(cssIv);
    }, 1000);
  }, 500);

  /* 2 ── Viewport ────────────────────────────────────────────────────────── */
  var meta = document.querySelector('meta[name=viewport]');
  if (!meta) { meta = document.createElement('meta'); meta.name = 'viewport'; document.head.appendChild(meta); }
  meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';

  /* 3 ── Touch → Mouse bridge (fixes model picker, quick-pick, dropdowns) ── */
  var INTERACTIVE = [
    '.quick-input-widget', '.context-menu', '.context-view',
    '.monaco-dropdown', '.dropdown-menu', '.select-container',
    '.monaco-list-row', '.action-item', '.menubar-menu-button',
    '.chat-widget', '.interactive-session .chat-input-part button',
    '.codicon', '.monaco-icon-label', '.quick-input-action',
    '[role="option"]', '[role="menuitem"]', '[role="button"]',
    '.suggest-widget .monaco-list-row',
    '.parameter-hints-widget', '.notification-list-item',
    '.monaco-dialog-box button'
  ].join(',');

  function synth(type, touch, target) {
    target.dispatchEvent(new MouseEvent(type, {
      bubbles: true, cancelable: true, view: window, detail: 1,
      screenX: touch.screenX, screenY: touch.screenY,
      clientX: touch.clientX, clientY: touch.clientY,
      button: 0, buttons: type === 'mousedown' ? 1 : 0
    }));
  }

  document.addEventListener('touchstart', function(e) {
    var el = e.target;
    if (el.closest && el.closest(INTERACTIVE)) {
      var tc = e.touches[0];
      synth('mouseover', tc, el); synth('mouseenter', tc, el); synth('mousedown', tc, el);
    }
  }, { passive: true });

  document.addEventListener('touchend', function(e) {
    var el = e.target;
    if (el.closest && el.closest(INTERACTIVE)) {
      var tc = e.changedTouches[0];
      synth('mouseup', tc, el); synth('click', tc, el);
    }
  }, { passive: true });

  /* Patch <select> for model picker (native select sometimes used) */
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

  /* 4 ── Heartbeat every 20s: keeps WiFi radio + WebSocket alive ──────────── */
  function heartbeat() {
    try {
      fetch('https://github.com/favicon.ico', { mode: 'no-cors', cache: 'no-store',
        signal: AbortSignal.timeout(5000) }).catch(function(){});
    } catch(_){}
  }
  heartbeat();
  setInterval(heartbeat, 20000);

  /* 5 ── Auto-reconnect when app returns to foreground ───────────────────── */
  var _wasHidden = false;
  document.addEventListener('visibilitychange', function() {
    if (document.hidden) { _wasHidden = true; return; }
    if (!_wasHidden) return;
    _wasHidden = false;
    heartbeat();
    setTimeout(function() {
      /* VS Code "Reload window" button */
      var btn = document.querySelector(
        '.reload-window, [class*="reload"][class*="button"], ' +
        '[aria-label*="Reload Window"], button[data-action="reconnect"], ' +
        '[aria-label*="Reconnect"], [title*="Reload"]'
      );
      if (btn) { btn.click(); return; }
      /* GitHub Codespaces "offline" page */
      var offline = document.querySelector('[data-testid="offline-error"] button');
      if (offline) { offline.click(); return; }
      /* Last resort: soft reload if still on a codespace URL */
      var h = window.location.href;
      if (h.includes('.github.dev') || h.includes('vscode.dev')) window.location.reload();
    }, 1500);
    setTimeout(function() { heartbeat(); }, 4000);
  });

  /* 6 ── Web Locks: prevent background JS throttling ─────────────────────── */
  if (navigator.locks && navigator.locks.request) {
    navigator.locks.request('cm_keepalive', { mode: 'shared' }, function() {
      return new Promise(function() {});
    });
  }

})();
""";

// ─── Sidebar toggles ─────────────────────────────────────────────────────────
const _toggleSidebarJs  = r"(function(){document.body.classList.toggle('cm-sidebar-on');})();";
const _toggleCopilotJs  = r"(function(){document.body.classList.toggle('cm-copilot-on');})();";

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
  bool _loading = true;
  int  _progress = 0;
  String _title    = 'Codespaces';
  bool _isVSCode   = false;
  bool _sidebarOn  = false;
  bool _copilotOn  = false;

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
          _loading = true;
          _sidebarOn = false;
          _copilotOn = false;
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
            await _inject();
            await Future.delayed(const Duration(seconds: 2));
            await _inject();
            await Future.delayed(const Duration(seconds: 5));
            await _inject();
            _startBgService();
          }
        },
        onNavigationRequest: (_) => NavigationDecision.navigate,
        onWebResourceError: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _inject() => _wvc.runJavaScript(_buildVscodeJs());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // WakeLock + WifiLock handle background — nothing needed here
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

  Future<void> _toggleCopilot() async {
    await _wvc.runJavaScript(_toggleCopilotJs);
    setState(() => _copilotOn = !_copilotOn);
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
                minHeight: 2,
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
      // Back button
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
      // Title with live indicator
      title: Row(children: [
        if (_isVSCode)
          Container(
            width: 7, height: 7,
            margin: const EdgeInsets.only(right: 7),
            decoration: const BoxDecoration(
              color: AppTheme.green, shape: BoxShape.circle),
          ),
        Expanded(
          child: Text(
            _title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isVSCode ? AppTheme.text : AppTheme.textSub,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
      // Action buttons
      actions: [
        if (_isVSCode) ...[
          // File tree toggle
          _barBtn(
            _sidebarOn ? Icons.folder_open_rounded : Icons.folder_outlined,
            _sidebarOn ? AppTheme.accent : AppTheme.muted,
            _toggleSidebar,
            tooltip: 'Fichiers',
          ),
          // Copilot toggle
          _barBtn(
            Icons.auto_awesome_rounded,
            _copilotOn ? AppTheme.accent : AppTheme.muted,
            _toggleCopilot,
            tooltip: 'Copilot',
          ),
        ],
        // Refresh
        _barBtn(
          Icons.refresh_rounded,
          AppTheme.muted,
          () { setState(() => _loading = true); _wvc.reload(); },
          tooltip: 'Rafraîchir',
        ),
        const SizedBox(width: 2),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
    );
  }

  Widget _barBtn(IconData icon, Color color, VoidCallback onTap, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onTap,
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
