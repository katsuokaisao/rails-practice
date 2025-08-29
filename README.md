# README

## Ruby version
3.3.7

## Docker Composeの起動
```bash
docker-compose up -d
```

## アプリケーションのアクセス方法
http://localhost:49152

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

### スキーマの出力

```bash
bin/rake db:custom:ridgepole_export
```

## テストの実行

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

## リンターの実行
### RuboCop
```bash
bundle exec rubocop
bundle exec rubocop -A
```

### ERB Lint
```bash
bundle exec erb_lint --lint-all
bundle exec erb_lint --lint-all --autocorrect
```

## Services (job queues, cache servers, search engines, etc.)
