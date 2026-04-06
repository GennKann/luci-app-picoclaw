<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b><a href="https://github.com/sipeed/picoclaw">PicoClaw</a> の OpenWrt LuCI Web管理インターフェース</b><br>
  <sub>AIゲートウェイを完全管理 — サービス管理からハードウェア制御まで</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-21.02%20%7C%2022.03%20%7C%2023.05%20%7C%2024.10%20%7C%2025.xx-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/LuCI-Web%20Interface-green?logo=lua" alt="LuCI">
  <img src="https://img.shields.io/badge/i18n-5%20Languages-purple" alt="i18n">
  <img src="https://img.shields.io/badge/Version-1.0.8-brightgreen" alt="Version">
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

## スクリーンショット

| ダッシュボード | 設定エディタ |
|:---:|:---:|
| ![ダッシュボード](Screenshots/screenshot_main.png) | ![設定](Screenshots/screenshot_config.png) |

| ハードウェア制御 | モバイル |
|:---:|:---:|
| ![ハードウェア](Screenshots/screenshot_hardware.png) | ![モバイル](Screenshots/screenshot_mobile.png) |

## 機能

### サービス管理
- **ダッシュボード** — サービス状態、PID、メモリ使用量、ポート監視
- **サービス制御** — PicoClawの開始/停止（kill-9強制停止対応）/再起動
- **自動起動切替** — 起動時自動開始の有効/無効
- **システムログ** — PicoClawログをリアルタイム表示・更新
- **オンライン更新** — 新バージョンの確認とUIからの直接更新

### 設定管理
- **チャンネル管理** — 接続済みチャンネルの表示（Feishu、Telegram、Discord、WeChat等）
- **WeChatステータス検出** — QRコードスキャン後のWeChat個人アカウントセッションを自動検知
- **フォーム設定エディタ** — AIモデル、プロバイダー、システム設定のUI
- **JSON設定エディタ** — JSON直接編集、バリデーション対応

### ハードウェアと拡張
- **ハードウェア制御** — システム情報、USBデバイス、GPIOピン（H/L切替対応）
- **スキル管理** — PicoClawスキルの表示・削除・インポートをUIから直接操作
- **Cronジョブ** — スケジュール済みタスクを一目で確認

### 内蔵プリセットスキル
3つのすぐ使えるAIスキルを同梱 — 管理ページからワンクリックでインストール：

| スキル | 説明 |
|:---|:---|
| **システム診断** | 自動ネットワーク/DNS/ゲートウェイ検出、ログ分析、トラブルシューティング |
| **設定バックアップ** | インタラクティブなバックアップフロー、環境チェック、オプションメニュー対応 |
| **スマートインストーラー** | opkg/is-opkgによるアプリ検索、あいまい説明マッチング対応 |

> これらのスキルは純粋なナレッジプロンプト（SKILL.md）です — PicoClaw本体の変更なしでAI応答能力を強化します。

## 動作要件

| 要件 | 詳細 |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+ / 22.03 / 23.05 / 24.10 / 25.xx / iStoreOS（LuCI導入済み） |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) がインストール済みで実行中 |
| **アーキテクチャ** | all（純粋Lua、x86-64 / aarch64 / armv7 / mipsle / riscv64 等全対応） |

> ⚠️ **重要**：`luci-app-picoclaw` はPicoClawの**Web管理インターフェースのみ**です。PicoClaw本体は含まれません。まだインストールしていない場合は、以下の手順1を先に完了してください。

## インストール

### 手順1：PicoClawのインストール（必須）

[PicoClaw Releases](https://github.com/sipeed/picoclaw/releases) からお使いのアーキテクチャに合わせてダウンロードしてください。

```bash
# x86-64の例（バージョンは適宜置換）
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw

# インストール確認
picoclaw --version
```

### 手順2：LuCIインターフェースのインストール（luci-app-picoclaw）

#### 方法1：iStoreアプリストア（推奨）

iStoreアプリで `picoclaw` を検索 → 直接インストール。
> v1.0.8よりiStore公式ソースにマージされました。ストアから直接利用可能です。

#### 方法2：IPKダウンロード

[Releases](https://github.com/GennKann/luci-app-picoclaw/releases/latest) から最新版をダウンロード：

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.0.8-1_all.ipk
opkg install luci-app-picoclaw_1.0.8-1_all.ipk
rm -rf /tmp/luci-*   # LuCIキャッシュクリア
```

#### 方法3：手動ファイルコピー

```bash
# コントローラー
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua
# テンプレート
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm
# Initスクリプト
cp scripts/picoclaw.init /etc/init.d/picoclaw && chmod +x /etc/init.d/picoclaw
# キャッシュクリア
rm -rf /tmp/luci-*
```

インストール後、新しいinit.dスクリプトを有効化するためにLuCIページで一度「再起動」を実行することをお勧めします：
> LuCI → サービス → PicoClaw → 「再起動」クリック

アクセス先：`http://<ルーターIP>/cgi-bin/luci/admin/services/picoclaw`

## よくある質問

### luci-app-picoclawをインストールしたけどページが開かない？
**PicoClaw本体**がインストールされていません。上記「手順1」を完了してからページをリフレッシュしてください。

### 停止ボタンを押してもプロセスが止まらない？
v1.0.7以前の既知の問題です。procdがプロセスを自動的に復活させていました。**v1.0.8で修正済み** — 停止機能が3段階方式（優雅停止 → pidof確認 + kill-9強制終了 → 待機）になりました。古いバージョンをお使いの場合はv1.0.8へアップグレードしてください。

### ログ更新時「Invalid CSRF token」と表示される？
v1.0.7以前の既知の問題です。**v1.0.8で修正済み** — 全フォーム送信でCSRFトークンが正しく付与されるようになっています。

### iStoreでpicoclawが見つからない？
ルーターターミナルで `opkg update` を実行してパッケージソースを更新するか、GitHub ReleasesからIPKを直接ダウンロードしてください。

### ページ上部にオレンジ色のバナーが表示されるのは？
luci-app-picoclawはインストール済みですがPicoClaw本体が未インストールです。バナークリックでワンクリックインストールできます（アーキテクチャを自動検出）。

## プロジェクト構成

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # LuCIコントローラー（バックエンドロジック）
│   └── view/
│       └── picoclaw/
│           └── main.htm           # LuCIテンプレート（HTML/CSS/JS）
├── skills/
│   ├── openwrt-diagnostics/
│   ├── openwrt-backup/
│   └── openwrt-app-installer/
├── scripts/
│   └── picoclaw.init              # OpenWrt init.dサービススクリプト
├── install.py                     # インタラクティブインストーラー
├── Screenshots/
└── README*.md                     # 多言語ドキュメント
```

## テクノロジースタック

| コンポーネント | テクノロジー |
|---|---|
| バックエンド | Lua (LuCI) + luci.jsonc |
| フロントエンド | HTML + CSS + JavaScript (サーバーサイドレンダリング) |
| サービスマネージャー | OpenWrt procd (init.d)、kill-9安全フォールバック付き |
| セキュリティ | 全フォームにCSRFトークン保護 |

## 更新履歴

[CHANGELOG.md](CHANGELOG.md) をご覧ください。

## ライセンス

[MIT License](LICENSE)

## クレジット

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) と [LuCI](https://github.com/openwrt/luci)
