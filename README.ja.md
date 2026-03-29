<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b><a href="https://github.com/sipeed/picoclaw">PicoClaw</a> の OpenWrt LuCI Web管理インターフェース</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/LuCI-Web%20Interface-green?logo=lua" alt="LuCI">
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

| デスクトップ | モバイル |
|:---:|:---:|
| ![ダッシュボード](Screenshots/screenshot_main.png) | ![モバイル](Screenshots/screenshot_mobile.png) |
| ![設定エディタ](Screenshots/screenshot_config.png) | — |

## ✨ 機能

- **ダッシュボード** — サービス状態、PID、メモリ使用量、ポート監視
- **サービス制御** — PicoClawの開始/停止/再起動
- **自動起動切替** — 起動時自動開始の有効/無効
- **チャンネル管理** — 接続済みチャンネルの表示（Feishu、Telegram、Discord、WeChat等）
- **フォーム設定エディタ** — AIモデル、プロバイダー、システム設定のUI
- **JSON設定エディタ** — JSON直接編集、バリデーション対応
- **多言語対応** — English、简体中文、日本語、Português、Deutsch
- **オンライン更新** — 新バージョンの確認とUIからの直接更新
- **システムログ** — PicoClawログをリアルタイム表示
- **レスポンシブデザイン** — デスクトップとモバイル対応

## 📋 動作要件

| 要件 | 詳細 |
|---|---|
| **OpenWrt** | 24.10 / 25.xx（LuCI導入済み） |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) がインストール済みで実行中 |

## 🚀 インストール

LuCIファイルをOpenWrtルーターにコピー：

```bash
# コントローラー
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# テンプレート
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# LuCIキャッシュをクリア
rm -rf /tmp/luci-*
```

アクセス先：`http://<ルーターIP>/cgi-bin/luci/admin/services/picoclaw`

## 🛠️ テクノロジースタック

| コンポーネント | テクノロジー |
|---|---|
| バックエンド | Lua (LuCI) |
| フロントエンド | HTML + CSS + JavaScript (サーバーサイドレンダリング) |
| サービスマネージャー | OpenWrt procd (init.d) |

## 📄 ライセンス

[MIT License](LICENSE)

## 🙏 クレジット

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) と [LuCI](https://github.com/openwrt/luci)
