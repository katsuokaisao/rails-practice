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
bin/rake db:custom:ridgepole_export
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

### スキーマの出力

```bash
bin/rake db:custom:ridgepole_export
```

## How to run the test suite

### テスト用データベースのセットアップ

```bash
bin/rake db:custom:setup_test
```

### RSpecテストの実行

```bash
bundle exec rspec
```

### E2Eテスト環境
このプロジェクトでは**Capybara + Playwright**を使用してE2Eテストを実装しています。

#### 使用技術
- **Capybara**: RubyのWebアプリケーション用テストフレームワーク
- **capybara-playwright-driver**: PlaywrightをCapybaraで使用するためのドライバー
- **Playwright**: 高速で安定したブラウザ自動化ツール


## Services (job queues, cache servers, search engines, etc.)
