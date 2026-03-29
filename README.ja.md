<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b><a href="https://github.com/sipeed/picoclaw">PicoClaw</a> の OpenWrt LuCI Web管理インターフェース</b><br>
  <sub>AIゲートウェイを完全管理 — サービス管理からハードウェア制御まで</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/LuCI-Web%20Interface-green?logo=lua" alt="LuCI">
  <img src="https://img.shields.io/badge/i18n-5%20Languages-purple" alt="i18n">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.zh.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt.md">Português</a>
</p>

---

## 📸 スクリーンショット

| ダッシュボード | 設定エディタ |
|:---:|:---:|
| ![ダッシュボード](Screenshots/screenshot_main.png) | ![設定](Screenshots/screenshot_config.png) |

| ハードウェア制御 | モバイル |
|:---:|:---:|
| ![ハードウェア](Screenshots/screenshot_hardware.png) | ![モバイル](Screenshots/screenshot_mobile.png) |

## ✨ 機能

### サービス管理
- **ダッシュボード** — サービス状態、PID、メモリ使用量、ポート監視
- **サービス制御** — PicoClawの開始/停止/再起動
- **自動起動切替** — 起動時自動開始の有効/無効
- **システムログ** — PicoClawログをリアルタイム表示
- **オンライン更新** — 新バージョンの確認とUIからの直接更新

### 設定管理
- **チャンネル管理** — 接続済みチャンネルの表示（Feishu、Telegram、Discord、WeChat等）
- **フォーム設定エディタ** — AIモデル、プロバイダー、システム設定のUI
- **JSON設定エディタ** — JSON直接編集、バリデーション対応

### ハードウェアと拡張
- **ハードウェア制御** — システム情報、USBデバイス、GPIOピン（H/L切替対応）
- **スキル管理** — PicoClawスキルの表示・削除・インポートをUIから直接操作
- **Cronジョブ** — スケジュール済みタスクを一目で確認

### 🆕 内蔵プリセットスキル
3つのすぐ使えるAIスキルを同梱 — 管理ページからワンクリックでインストール：

| スキル | 説明 |
|:---|:---|
| 🔍 **システム診断** | 自動ネットワーク/DNS/ゲートウェイ検出、ログ分析、トラブルシューティング |
| 💾 **設定バックアップ** | インタラクティブなバックアップフロー、環境チェック、オプションメニュー対応 |
| 📦 **スマートインストーラー** | opkg/is-opkgによるアプリ検索、あいまい説明マッチング対応 |

> これらのスキルは純粋なナレッジプロンプト（SKILL.md）です — PicoClaw本体の変更なしでAI応答能力を強化します。

## 📋 動作要件

| 要件 | 詳細 |
|---|---|
| **OpenWrt** | 24.10 / 25.xx（LuCI導入済み） |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) がインストール済みで実行中 |

## 🚀 インストール

### 方法1：手動インストール

```bash
# コントローラー
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# テンプレート
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# Initスクリプト（オプション、サービス制御用）
cp scripts/picoclaw.init /etc/init.d/picoclaw
chmod +x /etc/init.d/picoclaw

# プリセットスキル（オプション）
cp -r skills/openwrt-diagnostics /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-backup /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-app-installer /usr/lib/lua/luci/picoclaw-skills/

# LuCIキャッシュをクリア
rm -rf /tmp/luci-*
```

アクセス先：`http://<ルーターIP>/cgi-bin/luci/admin/services/picoclaw`

### 方法2：iStore（近日公開）

[iStoreアプリストア](https://github.com/istoreos/openwrt-app-actions)に提出済みです。承認後、ルーターのiStoreから直接インストール可能になります。

## 📁 プロジェクト構成

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # LuCIコントローラー（バックエンドロジック）
│   └── view/
│       └── picoclaw/
│           └── main.htm           # LuCIテンプレート（HTML/CSS/JS、サーバーサイドレンダリング）
├── skills/
│   ├── openwrt-diagnostics/
│   │   └── SKILL.md              # システム診断AIスキル
│   ├── openwrt-backup/
│   │   └── SKILL.md              # 設定バックアップAIスキル
│   └── openwrt-app-installer/
│       └── SKILL.md              # スマートアプリインストーラーAIスキル
├── scripts/
│   ├── picoclaw.init              # OpenWrt init.dサービススクリプト
│   └── build-apk-25xx.sh          # Sipeed 25xxデバイスビルドスクリプト
├── install.py                     # インタラクティブインストーラー
├── Screenshots/                   # READMEスクリーンショット
└── README*.md                     # 多言語ドキュメント
```

## 🛠️ テクノロジースタック

| コンポーネント | テクノロジー |
|---|---|
| バックエンド | Lua (LuCI) + luci.jsonc |
| フロントエンド | HTML + CSS + JavaScript (サーバーサイドレンダリング) |
| サービスマネージャー | OpenWrt procd (init.d) |
| セキュリティ | 全フォームにCSRFトークン保護 |

## 📄 ライセンス

[MIT License](LICENSE)

## 🙏 クレジット

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) と [LuCI](https://github.com/openwrt/luci)
