<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b><a href="https://github.com/sipeed/picoclaw">PicoClaw</a> の OpenWrt LuCI Web管理インターフェース</b><br>
  <sub>サービス管理 · モデル設定 · ハードウェア制御</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx%20%7C%20iStoreOS-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/Version-1.1.3-brightgreen" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.zh.md">简体中文</a> ·
  日本語 ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt.md">Português</a>
</p>

---

## 📸 スクリーンショット

| ダッシュボード | 設定エディタ |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Config](Screenshots/screenshot_config.png) |

| ハードウェア制御 | モバイル表示 |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## ✨ 機能

- **サービス制御** — 起動 / 停止 / 再起動、自動起動設定、リアルタイムログ
- **チャンネル管理** — Feishu、Telegram、Discord、WeChatステータス検出
- **モデル設定** — フォームエディタ、プロバイダープリセット（Zhipu、DeepSeek、Qwen、OpenAI等）、APIキー安全保存
- **検索エンジン設定** — GLM Search、Baidu、DuckDuckGo、Brave、Tavily、Perplexity、SearXNG（GFW情報付き）
- **ハードウェア制御** — システム情報、USBデバイス、GPIO切替
- **スキル管理** — 表示、削除、インポート、3つの内蔵プリセット（診断、バックアップ、アプリインストーラ）
- **JSONエディタ** — 直接設定編集（検証付き）

## 📋 動作要件

| | 詳細 |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+（LuCI必須） |
| **PicoClaw** | 先にインストール必須 — これはWeb UIのみ |
| **アーキテクチャ** | all（純粋Lua） |

## 🚀 インストール

### ステップ1: PicoClawのインストール

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version
```

### ステップ2: LuCIインターフェースのインストール

**iStore**（推奨）— `picoclaw` を検索 → インストール

**またはIPKをダウンロード：**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*
```

アクセス：`http://<ルーターIP>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 モデル設定

**設定エディタ**タブ → **モデルリスト**セクション：

1. **モデルを追加**（またはプロバイダープリセットボタン）をクリック
2. 入力：モデル名、プロバイダー、モデルID、APIベース（自動入力）、APIキー
3. ドロップダウンから**デフォルトモデル**を設定
4. **保存**をクリック

**対応プロバイダー：** Zhipu · DeepSeek · Qwen · OpenAI · Anthropic · OpenRouter · Ollama

> APIキーはPicoClawの二重ファイルセキュリティシステム（`config.json`プレースホルダー + `.security.yml`実際のキー）で安全に保存されます。

## 🔍 検索エンジン

| エンジン | 中国国内 | |
|---|:---:|---|
| GLM Search | ✅ | 推奨 |
| Baidu | ✅ | 代替 |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | GFWでブロック |
| SearXNG | ⚠️ | セルフホスト、インスタンスによる |

## ❓ FAQ

| 質問 | 回答 |
|---|---|
| ページが読み込まれない？ | PicoClawバイナリを先にインストール（ステップ1） |
| 「インターネットアクセス権がない」？ | 検索エンジンをGLM SearchまたはBaiduに切替 |
| iStoreで見つからない？ | `opkg update`を実行またはReleasesからIPKをダウンロード |
| APIキーが`[NOT_HERE]`と表示？ | 正常 — 実際のキーは`.security.yml`にあり、LuCI UIで管理 |

## 変更履歴

[CHANGELOG.md](CHANGELOG.md)を参照。

## 📄 ライセンス

[MIT License](LICENSE)
