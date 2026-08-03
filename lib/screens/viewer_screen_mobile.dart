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
const _vscodeCss = r"""
/* ══ Codespace Mobile v3.0 — full mobile fix ════════════════════════════════ */

/* ── Workbench root ──────────────────────────────────────────────────────── */
.monaco-workbench {
  display: flex !important;
  flex-direction: row !important;
  width: 100% !important;
  overflow: hidden !important;
  -webkit-user-select: none !important;
  user-select: none !important;
}

/* ── Activity bar: fully removed ────────────────────────────────────────── */
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
  flex: 0 0 0px !important;
  flex-basis: 0px !important;
  overflow: hidden !important;
  opacity: 0 !important;
  pointer-events: none !important;
  position: absolute !important;
  left: -9999px !important;
}

/* ── Split-view containers: allow full reflow ────────────────────────────── */
.monaco-workbench .monaco-split-view2,
.monaco-workbench .monaco-grid-view,
.monaco-workbench .monaco-grid-branch-node {
  width: 100% !important;
  overflow: hidden !important;
}

/* ── Split-view-view: DO NOT clip — sidebar/auxiliarybar live here ────────
   overflow:hidden here is the #1 cause of "rogné" sidebar content.         */
.monaco-workbench .split-view-view {
  overflow: visible !important;
}
/* Inner sashes and panes can still clip their own scroll areas */
.monaco-workbench .split-view-view > .pane,
.monaco-workbench .split-view-view > .composite,
.monaco-workbench .split-view-view > .part {
  overflow: hidden !important;
}

/* ── Sidebar (left panel: Explorer, Search, etc.) ────────────────────────── */
.monaco-workbench .part.sidebar {
  overflow: visible !important;
  min-width: 0 !important;
}
.monaco-workbench .part.sidebar .composite.title {
  overflow: visible !important;
  height: 35px !important;
  line-height: 35px !important;
}
.monaco-workbench .part.sidebar .composite.viewlet {
  overflow: hidden !important;
  height: 100% !important;
}
.monaco-workbench .part.sidebar .pane-header {
  min-height: 40px !important;
  overflow: visible !important;
}
.monaco-workbench .part.sidebar .pane-body {
  overflow: hidden !important;
}

/* ── Auxiliary bar (right panel: Copilot / Agent / Chat) ─────────────────── */
.monaco-workbench .part.auxiliarybar {
  overflow: visible !important;
  min-width: 0 !important;
}
.monaco-workbench .part.auxiliarybar .composite.title {
  overflow: visible !important;
  height: 35px !important;
  line-height: 35px !important;
}
.monaco-workbench .part.auxiliarybar .composite.viewlet,
.monaco-workbench .part.auxiliarybar .view-container {
  overflow: hidden !important;
  height: 100% !important;
}
.monaco-workbench .part.auxiliarybar .pane-header {
  min-height: 40px !important;
  overflow: visible !important;
}
.monaco-workbench .part.auxiliarybar .pane-body {
  overflow: hidden !important;
}
/* Copilot chat model picker area — must not be clipped */
.monaco-workbench .part.auxiliarybar .chat-input-part,
.monaco-workbench .part.auxiliarybar .interactive-input-box {
  overflow: visible !important;
}

/* ── Editor group ────────────────────────────────────────────────────────── */
.monaco-workbench .part.editor {
  flex: 1 1 auto !important;
  min-width: 0 !important;
}
.editor-container,
.editorContainer {
  width: 100% !important;
  min-width: 0 !important;
}

/* ── Tabs: bigger hit targets ────────────────────────────────────────────── */
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

/* ── Action bar buttons ───────────────────────────────────────────────────── */
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

/* ── Terminal ────────────────────────────────────────────────────────────── */
.part.panel { min-height: 180px !important; }
.xterm { font-size: 13px !important; line-height: 1.4 !important; }
.xterm-viewport { touch-action: pan-y !important; overflow-y: auto !important; }
.xterm-screen canvas { touch-action: none !important; }

/* ── Monaco editor scroll ────────────────────────────────────────────────── */
.monaco-scrollable-element { -webkit-overflow-scrolling: touch !important; }
.monaco-editor .overflow-guard { touch-action: pan-x pan-y !important; }

/* ── Quick-pick / command palette ────────────────────────────────────────── */
.quick-input-widget, .monaco-quick-input-widget {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
  overflow: visible !important;
}
.quick-input-list .monaco-list-row {
  min-height: 44px !important;
  line-height: 44px !important;
  pointer-events: auto !important;
  touch-action: manipulation !important;
}

/* ── Context menus & dropdowns ───────────────────────────────────────────── */
.context-menu, .context-view,
.monaco-dropdown, .dropdown, .dropdown-menu,
.select-container, .select-container select, .monaco-select-box {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
}
.context-menu .action-item,
.context-view .action-item { min-height: 36px !important; }

/* ── Model / AI picker (Copilot chat model selector) ─────────────────────── */
[class*="modelPicker"], [class*="model-picker"],
.chat-model-picker, .chat-model-picker-dropdown,
.model-picker, .model-picker-widget,
[aria-label*="model" i], [aria-label*="Model" i],
[title*="model" i], [title*="Model" i],
.chat-model-item, .chat-model-selector,
.interactive-session [class*="model"],
.chat-widget [class*="model"] {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 4000 !important;
  overflow: visible !important;
}
/* Native <select> inside model pickers */
select, select option {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  -webkit-tap-highlight-color: rgba(47,129,247,0.18) !important;
  font-size: 14px !important;
  min-height: 36px !important;
}

/* ── Notifications / dialogs ─────────────────────────────────────────────── */
.notification-toast, .notifications-toasts,
.dialog-box, .dialog-shadow, .monaco-dialog-box {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
}
.monaco-dialog-box button { min-height: 36px !important; padding: 0 16px !important; }

/* ── Suggest / parameter hints ───────────────────────────────────────────── */
.suggest-widget, .parameter-hints-widget {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  z-index: 3000 !important;
}
.suggest-widget .monaco-list-row { min-height: 36px !important; }

/* ── Copilot / chat / agent ──────────────────────────────────────────────── */
.chat-widget, .inline-chat-widget,
.interactive-session, .chat-input-part,
.chat-list-item, .chat-editing-session {
  pointer-events: auto !important;
  touch-action: manipulation !important;
}
.interactive-input-box .input { min-height: 48px !important; }
.chat-input-part .toolbar { overflow: visible !important; }

/* ── Generic interactive ─────────────────────────────────────────────────── */
[role="option"], [role="menuitem"], [role="listbox"],
[role="button"], [role="tab"],
.menubar-menu-button, .codicon, .monaco-icon-label {
  pointer-events: auto !important;
  touch-action: manipulation !important;
  -webkit-tap-highlight-color: rgba(47,129,247,0.18) !important;
}

/* ── Preserve text selection in editors ──────────────────────────────────── */
.monaco-editor, .xterm, .chat-widget, .interactive-session {
  -webkit-user-select: text !important;
  user-select: text !important;
}
""";

// ─── Main VS Code JS patch ───────────────────────────────────────────────────
String _buildVscodeJs() => r"""
(function() {
  'use strict';
  if (window.__cmPatch30) return;
  window.__cmPatch30 = true;

  /* 1 ── CSS injection ───────────────────────────────────────────────────── */
  var CSS = `""" + _vscodeCss.replaceAll('`', r'\`') + r"""`;

  function injectCss() {
    var el = document.getElementById('cm-patch-v10');
    if (!el) {
      el = document.createElement('style');
      el.id = 'cm-patch-v10';
      (document.head || document.documentElement).appendChild(el);
    }
    el.textContent = CSS;
  }

  function workbenchReady() {
    return !!document.querySelector('.monaco-workbench');
  }

  /* Zero activity-bar CSS variables + force reflow */
  function fixLayout() {
    var root = document.documentElement;
    [
      '--activity-bar-width', '--activitybar-width',
      '--activity-bar-compact-width', '--activitybar-compact-width',
      '--activity-bar-part-size', '--activityBarPartSize'
    ].forEach(function(v) { root.style.setProperty(v, '0px'); });

    window.dispatchEvent(new Event('resize'));

    document.querySelectorAll(
      '.monaco-workbench .part.activitybar, .monaco-workbench .activitybar.part'
    ).forEach(function(n) {
      n.style.setProperty('display',    'none',  'important');
      n.style.setProperty('width',      '0',     'important');
      n.style.setProperty('max-width',  '0',     'important');
      n.style.setProperty('flex',       '0 0 0', 'important');
      n.style.setProperty('flex-basis', '0',     'important');
    });
  }

  /* Debounce mutation bursts */
  var _dbt = null;
  function debouncedApply() {
    if (!workbenchReady()) return;
    clearTimeout(_dbt);
    _dbt = setTimeout(function() { injectCss(); fixLayout(); }, 150);
  }

  /* Poll until workbench ready */
  var _poll = setInterval(function() {
    if (!workbenchReady()) return;
    clearInterval(_poll);

    injectCss();
    fixLayout();

    [500, 1500, 3000, 6000, 10000].forEach(function(ms) {
      setTimeout(function() { injectCss(); fixLayout(); }, ms);
    });

    new MutationObserver(debouncedApply).observe(document.documentElement, {
      childList: true, subtree: true,
      attributes: true, attributeFilter: ['style', 'class']
    });

    /* Re-inject CSS for 90s (lazy-loaded panels / agent mode) */
    var n = 0;
    var iv = setInterval(function() { injectCss(); if (++n >= 90) clearInterval(iv); }, 1000);
  }, 500);

  /* 2 ── Viewport ────────────────────────────────────────────────────────── */
  (function() {
    var m = document.querySelector('meta[name=viewport]');
    if (!m) { m = document.createElement('meta'); m.name = 'viewport';
      (document.head || document.documentElement).appendChild(m); }
    m.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
  })();

  /* 3 ── Touch → Mouse bridge ─────────────────────────────────────────────
     Converts touch events to full mouse event sequences so VS Code
     hover-dependent UI (layout buttons, model picker, dropdowns) works.
  ── */
  var INTERACTIVE = [
    /* Title / layout buttons */
    '.action-item', '.action-label',
    '.title-actions .action-item', '.editor-actions .action-item',
    '.global-actions .action-item', '[class*="titlebar"] .action-item',
    /* Toolbar / menu bar */
    '.menubar-menu-button', '.toolbar-toggle-more',
    /* Tabs */
    '.tab', '.tab-close-button', '.tabs-and-actions-container .action-item',
    /* Tree / list rows */
    '.monaco-list-row', '.monaco-tree-row',
    /* Overlays */
    '.quick-input-widget', '.context-menu', '.context-view',
    '.monaco-dropdown', '.dropdown-menu',
    '.select-container', '.monaco-select-box',
    '.quick-input-action',
    /* Model / AI pickers — Copilot chat model selector */
    '[class*="modelPicker"]', '[class*="model-picker"]',
    '.chat-model-picker', '.chat-model-picker-dropdown',
    '.model-picker', '.model-picker-widget',
    '.chat-model-item', '.chat-model-selector',
    '[aria-label*="model" i]', '[aria-label*="Model" i]',
    /* Chat / Copilot */
    '.chat-widget', '.interactive-session .chat-input-part button',
    '.chat-execute-toolbar .action-item',
    '.chat-input-part .toolbar .action-item',
    /* Suggest / hints */
    '.suggest-widget .monaco-list-row', '.parameter-hints-widget',
    /* Notifications / dialogs */
    '.notification-list-item', '.monaco-dialog-box button',
    /* ARIA roles */
    '[role="option"]', '[role="menuitem"]', '[role="button"]', '[role="tab"]',
    /* Icons & labels */
    '.codicon', '.monaco-icon-label',
    /* Breadcrumbs */
    '.breadcrumb-item',
    /* Inline chat / agent */
    '.inline-chat-widget .action-item',
    '.chat-editing-session .action-item'
  ].join(',');

  function synth(type, touch, target) {
    target.dispatchEvent(new MouseEvent(type, {
      bubbles: true, cancelable: true, view: window, detail: 1,
      screenX: touch.screenX, screenY: touch.screenY,
      clientX: touch.clientX, clientY: touch.clientY,
      button: 0, buttons: (type === 'mousedown' || type === 'mousemove') ? 1 : 0
    }));
  }

  /* Find the deepest matching element from a point */
  function hitTest(x, y) {
    var els = document.elementsFromPoint(x, y);
    for (var i = 0; i < els.length; i++) {
      if (els[i].closest && els[i].closest(INTERACTIVE)) {
        return els[i].closest(INTERACTIVE);
      }
    }
    return null;
  }

  document.addEventListener('touchstart', function(e) {
    var t = e.touches[0];
    var hit = hitTest(t.clientX, t.clientY);
    if (!hit) return;
    /* Prevent ghost click & double-activation */
    e.preventDefault();
    synth('mouseover',  t, hit);
    synth('mouseenter', t, hit);
    synth('mousemove',  t, hit);
    synth('mousedown',  t, hit);
  }, { passive: false, capture: false });

  document.addEventListener('touchend', function(e) {
    var t = e.changedTouches[0];
    var hit = hitTest(t.clientX, t.clientY);
    if (!hit) return;
    e.preventDefault();
    synth('mouseup',    t, hit);
    synth('click',      t, hit);
    synth('mouseleave', t, hit);
  }, { passive: false, capture: false });

  document.addEventListener('touchmove', function(e) {
    var el = e.target;
    if (el.closest && el.closest('.quick-input-widget, .context-menu, .monaco-dialog-box')) {
      e.preventDefault();
    }
  }, { passive: false });

  /* 4 ── Native <select> patch (model picker dropdown) ────────────────────
     VS Code sometimes uses a native <select> for model selection.
     On Android WebView, the native select works but needs pointer-events.
     Also fire 'change' and 'input' so VS Code's listener updates the model.
  ── */
  function patchSelects() {
    document.querySelectorAll('select').forEach(function(s) {
      if (s.__cmPatched) return;
      s.__cmPatched = true;
      s.style.pointerEvents = 'auto';
      s.style.touchAction = 'manipulation';
      s.style.fontSize = '14px';
      s.style.minHeight = '36px';
      s.addEventListener('change', function() {
        s.dispatchEvent(new Event('input', { bubbles: true }));
      });
    });
  }
  patchSelects();
  new MutationObserver(patchSelects).observe(
    document.documentElement, { childList: true, subtree: true }
  );

  /* 5 ── Heartbeat: keep WiFi radio + WebSocket alive ─────────────────────── */
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

  /* 6 ── Auto-reconnect on foreground resume ──────────────────────────────── */
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

  /* 7 ── Web Locks: prevent background JS throttling ─────────────────────── */
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
            await _inject();
            await Future.delayed(const Duration(seconds: 3));
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
