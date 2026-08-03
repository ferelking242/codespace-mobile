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
// Rules are injected ONLY after .monaco-workbench is present (workbench-ready
// gate in the JS patch below). Never touches :root variables so VS Code's
// own layout initialisation is never disturbed.
const _vscodeCss = r"""
/* ══ Codespace Mobile v2.0 ══════════════════════════════════════════════════ */

/* ── Activity bar: useless on mobile, reclaim the space ─────────────────── */
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

/* ── Editor: always fills full width after activity bar removal ──────────── */
.monaco-workbench .part.editor,
.editor-container,
.editorContainer {
  flex: 1 1 auto !important;
  width: 100% !important;
  min-width: 0 !important;
  left: 0 !important;
}

/* ── Sidebar & auxiliary bar: let VS Code's own UI control them ──────────── */
/* No forced hide — VS Code's built-in toggle handles it natively.            */

/* ── Tabs: bigger hit targets for fingers ────────────────────────────────── */
.tabs-and-actions-container,
.monaco-workbench .part.editor .tabs-and-actions-container {
  height: 46px !important;
  min-height: 46px !important;
}
.tabs-container .tab {
  height: 46px !important;
  padding: 0 14px !important;
}
.tab-label { font-size: 13px !important; }
.tab-close-button { width: 28px !important; height: 28px !important; }

/* ── Action bar buttons (sidebar, copilot icons in title bar) ────────────── */
.action-item .action-label,
.actions-container .action-item {
  min-width: 36px !important;
  min-height: 36px !important;
}

/* ── Breadcrumbs ─────────────────────────────────────────────────────────── */
.breadcrumbs-control .breadcrumb-item { font-size: 12px !important; }

/* ── Status bar ──────────────────────────────────────────────────────────── */
.part.statusbar {
  height: 26px !important;
  min-height: 26px !important;
}
.statusbar-item a, .statusbar-item { font-size: 11px !important; }

/* ── Terminal: touch-scroll + readable font ──────────────────────────────── */
.part.panel { min-height: 180px !important; }
.xterm { font-size: 13px !important; line-height: 1.4 !important; }
.xterm-viewport { touch-action: pan-y !important; overflow-y: auto !important; }
.xterm-screen canvas { touch-action: none !important; }

/* ── Monaco editor: smooth finger scrolling ──────────────────────────────── */
.monaco-scrollable-element {
  -webkit-overflow-scrolling: touch !important;
}
.monaco-editor .overflow-guard {
  touch-action: pan-x pan-y !important;
}

/* ── Quick-pick / command palette ─────────────────────────────────────────── */
.quick-input-widget, .monaco-quick-input-widget {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
}
.quick-input-list .monaco-list-row {
  min-height: 44px !important;
  line-height: 44px !important;
  pointer-events: auto !important;
  touch-action: manipulation !important;
}

/* ── Context menus & dropdowns ────────────────────────────────────────────── */
.context-menu, .context-view,
.monaco-dropdown, .dropdown, .dropdown-menu,
.select-container, .select-container select, .monaco-select-box {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
}
.context-menu .action-item,
.context-view .action-item {
  min-height: 36px !important;
}

/* ── Notifications / dialogs ──────────────────────────────────────────────── */
.notification-toast, .notifications-toasts,
.dialog-box, .dialog-shadow, .monaco-dialog-box {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
}
.monaco-dialog-box button { min-height: 36px !important; padding: 0 16px !important; }

/* ── Suggest / parameter hints ────────────────────────────────────────────── */
.suggest-widget, .parameter-hints-widget {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
}
.suggest-widget .monaco-list-row { min-height: 36px !important; }

/* ── Copilot / chat ───────────────────────────────────────────────────────── */
.chat-widget, .inline-chat-widget,
.interactive-session, .chat-input-part,
.chat-list-item {
  pointer-events: auto !important;
  touch-action: manipulation !important;
}
.interactive-input-box .input { min-height: 48px !important; }

/* ── Generic interactive elements ────────────────────────────────────────── */
[role="option"], [role="menuitem"], [role="listbox"],
.menubar-menu-button, .codicon, .monaco-icon-label {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  -webkit-tap-highlight-color: rgba(47,129,247,0.18) !important;
}

/* ── Disable text selection during touch drag (feels native) ─────────────── */
.monaco-workbench { -webkit-user-select: none !important; user-select: none !important; }
.monaco-editor, .xterm, .chat-widget, .interactive-session {
  -webkit-user-select: text !important; user-select: text !important;
}
""";

// ─── Main VS Code JS patch ───────────────────────────────────────────────────
String _buildVscodeJs() => r"""
(function() {
  'use strict';
  if (window.__cmPatch20) return;
  window.__cmPatch20 = true;

  /* 1 ── CSS injection ───────────────────────────────────────────────────── */
  var CSS = `""" + _vscodeCss.replaceAll('`', r'\`') + r"""`;

  function injectCss() {
    var el = document.getElementById('cm-patch-v6');
    if (!el) {
      el = document.createElement('style');
      el.id = 'cm-patch-v6';
      (document.head || document.documentElement).appendChild(el);
    }
    el.textContent = CSS;
  }

  /* ── Workbench-ready gate ───────────────────────────────────────────────
     CSS and observer ONLY activate after .monaco-workbench is in the DOM.
     Injecting before that corrupts VS Code's layout boot and leaves the
     page stuck on "Setting up your workspace".
  ── */
  function workbenchReady() {
    return !!document.querySelector('.monaco-workbench');
  }

  /* Debounce: coalesce rapid mutation bursts into one injection */
  var _dbt = null;
  function debouncedInject() {
    if (!workbenchReady()) return;
    clearTimeout(_dbt);
    _dbt = setTimeout(function() {
      injectCss();
      /* Strip any inline width VS Code re-adds to the activity bar */
      document.querySelectorAll(
        '.monaco-workbench .part.activitybar, .monaco-workbench .activitybar.part'
      ).forEach(function(n) {
        n.style.setProperty('display',    'none',  'important');
        n.style.setProperty('width',      '0',     'important');
        n.style.setProperty('max-width',  '0',     'important');
      });
    }, 150);
  }

  /* Poll until workbench is ready, then inject and start observer */
  var _poll = setInterval(function() {
    if (!workbenchReady()) return;
    clearInterval(_poll);
    injectCss();

    new MutationObserver(debouncedInject).observe(document.documentElement, {
      childList: true, subtree: true,
      attributes: true, attributeFilter: ['style', 'class']
    });

    /* Retry for 30 s (VS Code lazy-loads panels) */
    var n = 0;
    var iv = setInterval(function() { injectCss(); if (++n >= 30) clearInterval(iv); }, 1000);
  }, 500);

  /* 2 ── Viewport ────────────────────────────────────────────────────────── */
  (function() {
    var m = document.querySelector('meta[name=viewport]');
    if (!m) { m = document.createElement('meta'); m.name = 'viewport'; (document.head || document.documentElement).appendChild(m); }
    m.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
  })();

  /* 3 ── Touch → Mouse bridge ─────────────────────────────────────────────
     Fixes: command palette, context menus, dropdowns, quick-pick, copilot
     chat buttons — all require real mousedown/mouseup/click events.
  ── */
  var INTERACTIVE = [
    '.quick-input-widget', '.context-menu', '.context-view',
    '.monaco-dropdown', '.dropdown-menu', '.select-container',
    '.monaco-list-row', '.action-item', '.menubar-menu-button',
    '.chat-widget', '.interactive-session .chat-input-part button',
    '.codicon', '.monaco-icon-label', '.quick-input-action',
    '[role="option"]', '[role="menuitem"]', '[role="button"]',
    '.suggest-widget .monaco-list-row', '.parameter-hints-widget',
    '.notification-list-item', '.monaco-dialog-box button',
    '.tab', '.tab-close-button'
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
      var t = e.touches[0];
      synth('mouseover', t, el); synth('mouseenter', t, el); synth('mousedown', t, el);
    }
  }, { passive: true });

  document.addEventListener('touchend', function(e) {
    var el = e.target;
    if (el.closest && el.closest(INTERACTIVE)) {
      var t = e.changedTouches[0];
      synth('mouseup', t, el); synth('click', t, el);
    }
  }, { passive: true });

  /* Patch <select> elements (model picker uses native selects) */
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

  /* 4 ── Heartbeat: keep WiFi radio + WebSocket alive ─────────────────────── */
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

  /* 5 ── Auto-reconnect on foreground resume ──────────────────────────────── */
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

  /* 6 ── Web Locks: prevent background JS throttling ─────────────────────── */
  if (navigator.locks && navigator.locks.request) {
    navigator.locks.request('cm_keepalive', { mode: 'shared' }, function() {
      return new Promise(function() {});
    });
  }

})();
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
  bool _loading = true;
  int  _progress = 0;
  String _title  = 'Codespaces';
  bool _isVSCode = false;

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
          _loading  = true;
          _isVSCode = _isVSCodeUrl(url);
          _title    = _titleFrom(url);
        }),
        onProgress: (p) => setState(() => _progress = p),
        onPageFinished: (url) async {
          setState(() {
            _loading  = false;
            _isVSCode = _isVSCodeUrl(url);
            _title    = _titleFrom(url);
          });
          if (_isVSCode) {
            // Inject immediately, then once more after a short delay in case
            // VS Code reinitialises its DOM on first load.
            await _inject();
            await Future.delayed(const Duration(seconds: 3));
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
      title: Row(children: [
        if (_isVSCode)
          Container(
            width: 7, height: 7,
            margin: const EdgeInsets.only(right: 7),
            decoration: const BoxDecoration(
              color: AppTheme.green, shape: BoxShape.circle,
            ),
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
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          color: AppTheme.muted,
          tooltip: 'Rafraîchir',
          onPressed: () {
            setState(() => _loading = true);
            _wvc.reload();
          },
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.border),
      ),
    );
  }
}
