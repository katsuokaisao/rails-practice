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

## i18n-tasksの使用方法

### 概要
i18n-tasksは、Railsプロジェクトで国際化（i18n）ファイルの管理を効率化するためのツールです。主に以下の機能を提供します：
- 未使用キーの検出
- 未翻訳キーの検出
- キーの整理・整形

### よく使うコマンド

#### 未翻訳キーを検出
```bash
bundle exec i18n-tasks missing
```
- `ja.yml`にあるけど`en.yml`にないキーなどを一覧表示します。

#### 未使用キーを検出
```bash
bundle exec i18n-tasks unused
```
- ソースコード上で参照されていないキーを検出します。
- 例: `t('hello.world')`が使われていない場合に表示されます。

#### キーの並び替え・整形
```bash
bundle exec i18n-tasks normalize
```
- 各ロケールファイルのキーをソート・整形して統一感を出します。

#### 翻訳カバレッジを確認
```bash
bundle exec i18n-tasks health
```
- 未翻訳・未使用・重複キーなどをまとめてチェックします。

#### キー検索
```bash
bundle exec i18n-tasks find some.key
```
- 指定したキーがどのファイルにあるかを確認できます。



## アセットパイプラインのビルド
```bash
bin/rails assets:precompile
```

## 用語集

### 基本用語

#### ユーザー関連

| 用語                          | 説明                                             |
| --------------------------- | ---------------------------------------------- |
| **会員ユーザー**（Member User）     | 会員登録をしたユーザー。掲示板にお題を投稿したり、お題にコメントを投稿できる。        |
| **非会員ユーザー**（Guest User）     | 会員登録をしていないユーザー。掲示板の閲覧はできるが、投稿やコメントはできない。       |
| **モデレーター**（Moderator）       | 掲示板の運営を行うユーザ。通報の結果を審査するのが主な役割。    |

#### コンテンツ関連

| 用語                                 | 説明                                   |
| ---------------------------------- | ------------------------------------ |
| **お題**（Topic）                      | 掲示板に集まって人で話し合うためのテーマ。会員ユーザであれば誰でも立てることができる。   |
| **コメント**（Comment）                  | ユーザーがお題や他のコメントに対して述べる感想や意見。          |
| **編集履歴**（Comment History）          | コメントを編集した際に残る履歴。
| **バージョン番号**（Version No）            | 編集履歴を識別するための番号。    |

#### モデレーション関連

| 用語                           | 説明                                 |
| ---------------------------- | ---------------------------------- |
| **通報**（Report）               | コメントの非表示またはユーザーの停止を求める行為。          |
| **通報対象タイプ**（Target Type）     | 通報対象が「コメント非表示」か「ユーザー停止」かを示す区分。          |
| **通報理由種別**（Reason Type）     | 通報理由の分類。「スパム」「嫌がらせ」「わいせつ」「その他」がある。 |
| **通報理由テキスト**（Reason Text）    | 通報の具体的な理由                    |
| **通報者**（Reporter）            | 通報を行ったユーザー。                        |
| **通報対象ユーザー**（Target User）    | ユーザ停止の対象者ユーザ                   |
| **通報対象コメント**（Target Comment） | コメント非表示の対象のコメント                  |
| **審査**（Decision）             | 通報が適切かどうかを判定する行為。モデレーターが行う。        |
| **審査タイプ**（Decision Type）     | 審査の結果。「却下」「コメント非表示」「ユーザー利用停止」がある。  |
| **審査メモ**（Note）               | 審査する際のメモ                   |
| **審査者**（Decided By）          | 審査を行ったモデレーター。                      |
