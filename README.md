# paper-72h-reset

72 時間ごとにワールドが自動でリセットされる，[PaperMC](https://papermc.io/) サーバー向けの管理スクリプトです．

最低限の運用を想定しており，定期リセット・MOTD の更新・チャットへの残り時間の通知・バックアップ作成・再起動までをすべて自動で行います．

## 特徴

- 72 時間ごとにワールドをリセット（午前 4 時に設定します）
- 次回リセット時刻を MOTD に表示
- リセット前にチャットで警告を通知
- バックアップを Vanilla 互換の ZIP 形式で保存
- サーバーを自動で再起動

## 前提環境

- PaperMC（`paper.jar`）
- Java 実行環境（例：Java 21）
- bash / screen / zip / readlink / realpath が使える Linux または macOS 環境

## ディレクトリ構成（例）

```
/home/user/minecraft_server/
├── paper.jar
├── server.properties
├── world/                  ← 自動で削除・バックアップされます
├── world_nether/           ← 自動で削除・バックアップされます
├── world_the_end/
├── cron/
│   └── paper_reset_72h.sh  ← このスクリプトをここに置きます
└── backup/                 ← バックアップデータが ZIP で保存されます
```

## セットアップ手順

1. `paper_reset_72h.sh` を `cron/` ディレクトリなどに置く
2. `paper.jar` や `server.properties` はその親ディレクトリに配置
3. 実行権限を付与：

```
chmod +x paper_reset_72h.sh
```

4. cron で定期実行（例：10 分おきに実行）

```
*/10 * * * * /home/user/minecraft_server/cron/paper_reset_72h.sh
```

## 備考

- `reset_at.txt` が自動で生成され、次回リセット時刻が記録されます
- サーバーは `screen` セッション（デフォルト名：`minecraft`）で起動されます
