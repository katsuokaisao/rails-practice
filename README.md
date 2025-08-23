# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

## Ruby version
3.3.7

## Configuration

## Database set up

### 開発環境のセットアップ（リセット + スキーマ適用 + シード）

```bash
bin/rake db:custom:setup
```

このタスクは以下を順次実行します：
- データベースのドロップ・作成
- Ridgepoleによるスキーマ適用
- シードデータの投入

### テスト環境のセットアップ（リセット + スキーマ適用）

```bash
bin/rake db:custom:setup_test
```

このタスクは以下を順次実行します：
- テスト用データベースのドロップ・作成
- Ridgepoleによるスキーマ適用

### スキーマのみ適用

#### dry-run（変更内容の確認）

```bash
bin/rake db:custom:ridgepole_dry_run
```

#### 実際の適用

```bash
bin/rake db:custom:ridgepole_apply
```

## How to run the test suite

## Services (job queues, cache servers, search engines, etc.)
