# CI Workflows

## ファイル構成

- **`ci-pipeline.yml`**: メインとなる統合CIパイプラインですPull Request作成時やmainブランチへのプッシュ時にトリガーされ、後述の他のワークフローを順次実行します
- **`setup-mint.yml`**: Mint のインストール、キャッシュ、パッケージのブートストラップを行い、`.mint` ディレクトリをアーティファクトとしてアップロードするワークフローです
- **`package-tests.yml`**: Swift Packageのビルドとユニットテストを実行するワークフローです。テスト結果をJUnit形式で出力します。
- **`run-tests.yml`**: アプリのUIテストを実行するワークフロー`.github/scripts/` 配下の関数定義ファイルを `source` し、必要な関数（シミュレータ選択、UIテスト実行、結果検証など）を直接呼び出します
- **`build-unsigned-archive.yml`**: 署名なしのアーカイブ（.xcarchive）を作成するワークフロー`.github/scripts/` 配下の関数定義ファイルを `source` し、必要な関数（アーカイブビルド、結果検証など）を直接呼び出します
- **`code-quality.yml`**: コード品質チェック（SwiftFormat, SwiftLint）を実行します
- **`test-reporter.yml`**: テスト結果のレポートを作成し、PRにコメントします
- **`copilot-review.yml`**: GitHub CopilotによるPRレビューを自動化します

## CIの特徴

### ワークフローの分割
メインの`ci-pipeline.yml`が、Swift Packageテスト、UIテスト、コード品質チェック、アーカイブビルドなどの個別のワークフローを呼び出す構造になっています
コアなビルド・テスト・アーカイブ処理は、一部 `.github/scripts/` 配下のシェルスクリプト（例: `run-local-ci.sh` や `find-simulator.sh`）に関数として定義され、各ワークフローやローカル検証スクリプトが必要に応じてこれらを呼び出します

### 包括的なビルドプロセスの検証
Pull Requestや`main`ブランチへのプッシュ時に、以下の自動チェックを実行します
- コードフォーマット (SwiftFormat) と静的解析 (SwiftLint)
- Swift Packageのテスト（主にユニットテスト）と結果の検証
- UIテストと結果（xcresult）の検証
- リリース設定でのアーカイブビルドと結果の検証（`main`ブランチプッシュ時）

### Pull Request に自動でレビュー
Pull Requestに対して、テスト結果のレポート、GitHub Copilotによる自動レビューリクエスト、パイプライン全体の完了ステータス通知を行います

### 成果物管理
- 成果物管理: ビルドやテストの成果物はGitHub Artifactsとしてアップロード・管理されます
- 出力先を統一: 全てのビルド・テスト関連の成果物は、一貫して `ci-outputs/` ディレクトリ以下に出力されます

## 機能詳細

### `ci-pipeline.yml` (メインパイプライン)

- **トリガー**: `main`/`master`へのPush、`main`/`master`ターゲットのPR、手動実行
- **処理**:
    1.  Mint 環境セットアップ (`setup-mint.yml`)
    2.  Swift Package テスト (`package-tests.yml`)
    3.  コード品質チェック (`code-quality.yml`)
    4.  UIテスト実行 (`run-tests.yml`)
    5.  テスト結果レポート (PR時, `test-reporter.yml` - PackageテストとUIテストの結果を統合)
    6.  Copilotレビュー依頼 (PR時, `copilot-review.yml`)
    7.  アーカイブビルド検証 (`main` Push時, `build-unsigned-archive.yml`)
    8.  パイプライン完了ステータス通知 (PR時)

### `setup-mint.yml` (Mint依存関係セットアップ)

- **トリガー**: `ci-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  リポジトリをチェックアウト
    2.  Homebrewをセットアップ
    3.  Mintをインストール (`brew install mint`)
    4.  Mintパッケージをキャッシュ (`actions/cache`)
    5.  Mintパッケージをブートストラップ (`mint bootstrap`)

### `package-tests.yml` (Swift Package テスト実行)

- **トリガー**: `ci-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  リポジトリをチェックアウト (`actions/checkout`)
    2.  Xcode環境をセットアップ (`maxim-lobanov/setup-xcode`)
    3.  テスト結果出力用ディレクトリを作成 (`ci-outputs/test-results/package`)
    4.  Swift Packageをビルド (`swift build`)
    5.  Swift Packageをテスト (`swift test --xunit-output`)、JUnitレポート生成
    6.  テスト結果 (`.xml`) をアーティファクト (`package-test-results`) としてアップロード

### `run-tests.yml` (UIテスト実行)

- **トリガー**: `ci-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  リポジトリをチェックアウト (`actions/checkout`)
    2.  Mintパッケージのキャッシュを復元 (`actions/cache`)
    3.  Xcode環境をセットアップ (`maxim-lobanov/setup-xcode`)
    4.  Mintをインストール (`brew install mint`)
    5.  Xcodeプロジェクトを生成 (`mint run xcodegen generate`) - UIテストターゲット用
    6.  テスト結果出力用ディレクトリを作成 (`ci-outputs/test-results/ui`)
    7.  シミュレータ検索スクリプトに実行権限を付与 (`.github/scripts/find-simulator.sh`)
    8.  テスト用iOSシミュレータを選択
    9.  UIテストを実行 (`xcodebuild test`)、JUnitレポート生成、`xcbeautify` で結果を整形
    10. UIテスト結果バンドル (`.xcresult`) を検証
    11. UIテスト結果 (`.xcresult`, `.xml`) をアーティファクト (`ui-test-results`) としてアップロード

### `build-unsigned-archive.yml` (署名なしアーカイブ作成)

- **トリガー**: `ci-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  共通・ビルドステップ関数 (`build-archive.sh`) を `source`
    2.  アーカイブビルド (`build_archive_step`)
    3.  アーカイブ内容検証 (`verify_archive_step`)
    4.  `.xcarchive` をアーティファクト (`unsigned-archive`) としてアップロード

### `code-quality.yml` (コード品質チェック)

- **トリガー**: `ci-pipeline.yml` から `workflow_call` で呼び出し
- **処理**:
    1.  `mint-packages` アーティファクトをダウンロード
    2.  SwiftFormatを実行 (`mint run swiftformat`)
    3.  SwiftLint (`--strict`) を実行 (`mint run swiftlint`)
    4.  `git diff` でフォーマット変更がないか確認

### `test-reporter.yml` (テスト結果レポート)

- **トリガー**: `ci-pipeline.yml` から `workflow_call` で呼び出し (PR時)
- **処理**:
    1.  `ui-test-results` および `package-test-results` アーティファクトをダウンロード
    2.  JUnitレポートからGitHub Checksに結果を表示
    3.  PRにテスト結果サマリーをコメント (PackageテストとUIテストの結果を含む)

### `copilot-review.yml` (Copilotレビュー依頼)

- **トリガー**: `ci-pipeline.yml` から `workflow_call` で呼び出し (PR時)
- **処理**:
    1.  Copilotをレビュアーに追加
    2.  失敗時にエラーコメントをPRに投稿

## 使用方法

メインパイプライン (`ci-pipeline.yml`) は以下のタイミングで自動実行されます:

- **プッシュ時**: `main` または `master` ブランチへのプッシュ
- **PR作成/更新時**: `main` または `master` ブランチをターゲットとするPull Request
- **手動実行**: GitHub Actionsタブから `ci-pipeline.yml` を選択して実行可能

個別のワークフローは通常、直接実行するのではなく、`ci-pipeline.yml` によって呼び出されます

## ローカルでのCIプロセスの検証

GitHub Actions で実行される主要なCIステップ（Swift Packageテスト、UIテスト、アーカイブ）のコアロジックをローカルで検証するためのスクリプト (`.github/scripts/run-local-ci.sh`) を用意しています。このスクリプトは、コマンドライン引数に基づいて適切な処理を実行します。

Swift Packageのテストは `swift test` コマンドを中心に、UIテストとアーカイブは従来の `xcodebuild` コマンドベースの処理を踏襲しつつ、新しいワークフローの構成に合わせて調整されています。

初回実行前に、以下のコマンドでスクリプトに実行権限を付与してください
```shell
$ chmod +x .github/scripts/find-simulator.sh
$ chmod +x .github/scripts/run-local-ci.sh
```

### ビルドを含む検証

ローカル環境でビルドからテストやアーカイブを実行し、CIワークフローで実行されるコアな処理が期待通りかを確認します。

```shell
# 全てのステップ (Swift Packageビルド・テスト、UIテスト用ビルド・テスト、アーカイブビルド・検証) を実行
$ ./.github/scripts/run-local-ci.sh

# Swift Packageのビルドとテストを実行
$ ./.github/scripts/run-local-ci.sh --package-test

# UIテスト用ビルド + UIテストを実行・検証
$ ./.github/scripts/run-local-ci.sh --ui-test

# アーカイブのみを実行・検証
$ ./.github/scripts/run-local-ci.sh --archive-only

# Swift PackageテストとUIテストの両方を実行 (アーカイブなし)
$ ./.github/scripts/run-local-ci.sh --all-tests
```

### テストのみ実行 (ビルド成果物を再利用)

UIテストコードのみを修正した後、既存のビルド成果物 (`ci-outputs/test-results/DerivedData` for UI tests) を再利用して、UIテストのみを高速に再実行・検証します。
Swift Packageのテスト (`swift test`) は通常、インクリメンタルビルドを行うため、専用の `test-without-building` オプションは主にUIテスト用です。

事前に上記のコマンドで `--ui-test` などを実行してUIテスト用のビルド成果物を作成しておく必要があります。

```shell
# UIテストのみを再実行・検証 (ビルドなし)
$ ./.github/scripts/run-local-ci.sh --test-without-building --ui-test
```

## 技術仕様

- Xcodeバージョン: 16.2
- テスト環境: iOS シミュレータ (UIテスト用), macOS (Swift Packageテスト用)
- 依存ツール管理: Mint (SwiftFormat, SwiftLint, XcodeGen), Homebrew (xcbeautify), RubyGems (xcpretty)
- アーティファクト保持期間: ビルド関連 = 1日、テスト結果/アーカイブビルド = 7日
- 出力先ディレクトリ: `ci-outputs/`
  - `test-results/package`: Swift Packageテストの結果 (`.xml`)
  - `test-results/ui`: UIテストの結果 (`.xcresult`, `.xml`)
  - `test-results/DerivedData`: UIテスト用ビルドの中間生成物
  - `production/`: リリース用（署名なし）のアーカイブの結果

