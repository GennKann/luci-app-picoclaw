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
  <img src="https://img.shields.io/badge/Version-1.1.3-brightgreen" alt="Version">
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
- **検索エンジン設定** — Web検索プロバイダーの設定（GLM Search、Baidu、DuckDuckGo、Brave、Tavily、Perplexity、SearXNG）、中国ユーザー向けGFWヒント付き
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
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
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

## 🤖 モデル設定方法

PicoClawは複数のAIプロバイダーに対応しています。LuCI Web UI（設定エディタタブ）またはJSON設定の直接編集でモデルを設定できます。

### LuCI Web UI経由（推奨）

1. **LuCI → サービス → PicoClaw → 設定エディタ** に移動
2. **モデルリスト** セクションで **モデル追加** をクリック
3. 以下のフィールドを入力：
   - **モデル名** — 一意の識別子（例：`my-glm4`、`my-deepseek`）
   - **プロバイダー** — ドロップダウンから選択（Zhipu、OpenRouter、DeepSeek、Qwen、OpenAI、Anthropic等）
   - **モデル** — プロトコルプレフィックス付きモデル識別子（例：`zhipu://glm-4.5-air`、`deepseek://deepseek-chat`）
   - **APIベース** — プロバイダーAPIエンドポイント（プロバイダー選択で自動入力）
   - **API Key** — APIキー（安全に保存）
   - **有効** — オン/オフ切替
4. ドロップダウンから **デフォルトモデル** を設定
5. **保存** をクリックして適用

### 対応プロバイダー

| プロバイダー | モデルプレフィックス | APIベース | 備考 |
|---|---|---|---|
| Zhipu (智谱) | `zhipu://` | `https://open.bigmodel.cn/api/paas/v4` | 中国国内利用可能、推奨 |
| DeepSeek | `deepseek://` | `https://api.deepseek.com` | 中国国内利用可能 |
| Qwen (通義) | `dashscope://` | `https://dashscope.aliyuncs.com/compatible-mode/v1` | 中国国内利用可能 |
| OpenAI | `openai://` | `https://api.openai.com/v1` | 中国ではプロキシが必要 |
| Anthropic | `anthropic://` | `https://api.anthropic.com` | 中国ではプロキシが必要 |
| OpenRouter | `openrouter://` | `https://openrouter.ai/api/v1` | アグリゲーター、中国ではプロキシが必要 |

### JSON設定経由（上級者向け）

`/root/.picoclaw/config.json` を編集：

```json
{
  "model_list": [
    {
      "model_name": "glm-4.5-air",
      "model": "zhipu://glm-4.5-air",
      "api_base": "https://open.bigmodel.cn/api/paas/v4",
      "api_keys": [["[","N","O","T","_","H","E","R","E","]"]],
      "enabled": true
    }
  ]
}
```

> ⚠️ `config.json` のAPIキーはSecureString文字配列形式（`[NOT_HERE]`プレースホルダー）で保存されます。実際のキーは `/root/.picoclaw/.security.yml` に保存されます。LuCI経由で編集するとセキュア形式が自動的に保持されます。

## 🔍 検索エンジン設定

PicoClawはWeb検索を使用して最新情報を提供できます。**設定エディタ**タブで検索エンジンを設定します。

| エンジン | 中国国内利用 | 備考 |
|---|---|---|
| **GLM Search** (智谱検索) | ✅ | 中国国内ユーザー推奨 |
| **Baidu Search** | ✅ | 中国国内代替 |
| **DuckDuckGo** | ❌ | GFWでブロック |
| **Brave Search** | ❌ | GFWでブロック |
| **Tavily** | ❌ | API Key必要、GFWでブロック |
| **Perplexity** | ❌ | GFWでブロック |
| **SearXNG** | ⚠️ | セルフホスト、インスタンスの場所による |

> 💡 **中国国内ユーザーへのヒント**：`glm_search` または `baidu_search` を有効にし、DuckDuckGo/Braveを無効にして、GFWによる検索タイムアウトエラーを回避してください。

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

### PicoClawが天気やニュースの質問で「ネットワークにアクセスする権限がありません」と返す？
検索エンジンの設定が間違っています。DuckDuckGo、Brave、Googleは中国でGFWによりブロックされています。設定エディタタブで**GLM Search**または**Baidu Search**に切り替えてから、PicoClawを再起動してください。

### カスタムAIモデルを追加するには？
設定エディタタブ → モデルリストセクション → 「モデル追加」をクリック。プロバイダー、モデル名、API Keyを入力して保存すると、デフォルトモデルのドロップダウンに表示されます。

### config.jsonでAPI Keyが `[NOT_HERE]` と表示される？
これは正常です — PicoClawはセキュアストレージシステムを使用しています。実際のキーは `.security.yml` にあります。`config.json` の `[NOT_HERE]` を手動で置き換えないでください。LuCI UIでキーを管理してください。

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
