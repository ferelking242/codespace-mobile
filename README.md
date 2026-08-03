# 📱 Codespace Mobile

Android app (arm64-v8a) for GitHub Codespaces — mobile-friendly WebView with Copilot support.

## Features
- 🔐 GitHub PAT authentication (secure storage)
- 📋 List all your Codespaces with status
- ▶️ Start / Stop Codespaces
- 🌐 Open Codespace in optimized mobile WebView
- 💅 Auto-injected mobile CSS into VS Code
- 🤖 GitHub Copilot works via your subscription
- 🔧 Floating toolbar (hide/show, back, refresh)

## Download APK

Check the **[Actions tab](../../actions)** → latest build → `codespace-mobile-arm64` artifact.

## Build locally

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

## Stack
- **Flutter 3.22** + Dart
- `webview_flutter` for VS Code rendering
- `flutter_secure_storage` for token
- GitHub REST API v3
- GitHub Actions CI → arm64 APK

## Setup
1. Install APK on Android
2. Go to `github.com` → Settings → Developer Settings → Personal Access Tokens
3. Create token with scopes: `codespace`, `read:user`
4. Enter token in the app
