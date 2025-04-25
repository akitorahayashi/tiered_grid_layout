#!/bin/bash
set -euo pipefail

# === 設定 ===
OUTPUT_DIR="ci-outputs"
TEST_RESULTS_DIR="$OUTPUT_DIR/test-results"
# TEST_BUILD_DERIVED_DATA_DIR はテストビルドとテスト実行で共有
TEST_BUILD_DERIVED_DATA_DIR="$TEST_RESULTS_DIR/test-build"
PRODUCTION_DIR="$OUTPUT_DIR/production"
ARCHIVE_DIR="$PRODUCTION_DIR/archives"
PRODUCTION_DERIVED_DATA_DIR="$ARCHIVE_DIR/DerivedData"
EXPORT_DIR="$PRODUCTION_DIR/Export"
PROJECT_FILE="TieredGridLayout.xcodeproj"
APP_SCHEME="SampleApp"
UNIT_TEST_SCHEME="TieredGridLayoutTests"
UI_TEST_SCHEME="TieredGridLayoutUITests"

# === フラグ ===
run_unit_tests=false
run_ui_tests=false
run_archive=false
run_test_without_building=false # 新しいフラグ
run_all=true # デフォルト: 全実行

# === 引数解析 ===
specific_action_requested=false
only_testing_requested=false # テスト関連の引数のみかを判定

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --test-without-building)
      run_test_without_building=true
      run_archive=false # ビルドなしテストではアーカイブしない
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --all-tests)
      run_unit_tests=true
      run_ui_tests=true
      run_archive=false # --all-tests はアーカイブを含まない
      run_all=false
      specific_action_requested=true
      only_testing_requested=true
      shift
      ;;
    --unit-test)
      run_unit_tests=true
      run_archive=false # 個別テスト指定時はアーカイブしない
      run_all=false
      specific_action_requested=true
      only_testing_requested=true
      shift
      ;;
    --ui-test)
      run_ui_tests=true
      run_archive=false # 個別テスト指定時はアーカイブしない
      run_all=false
      specific_action_requested=true
      only_testing_requested=true
      shift
      ;;
    --archive-only)
      # --test-without-building と --archive-only は併用不可
      if [ "$run_test_without_building" = true ]; then
        echo "Error: --test-without-building cannot be used with --archive-only."
        exit 1
      fi
      run_unit_tests=false
      run_ui_tests=false
      run_archive=true
      run_all=false
      specific_action_requested=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# 引数なしなら全実行 (ビルド含む)
if [ "$specific_action_requested" = false ]; then
  run_unit_tests=true
  run_ui_tests=true
  run_archive=true
  run_test_without_building=false # 明示的にfalse
fi

# --test-without-building が指定されたが、--unit-test や --ui-test がない場合、両方実行
if [ "$run_test_without_building" = true ] && [ "$only_testing_requested" = false ]; then
    echo "--test-without-building specified without specific tests, running both unit and UI tests."
    run_unit_tests=true
    run_ui_tests=true
fi

# === ヘルパー関数 ===
step() {
  echo ""
  echo "──────────────────────────────────────────────────────────────────────"
  echo "▶️  $1"
  echo "──────────────────────────────────────────────────────────────────────"
}

success() {
  echo "✅ $1"
}

fail() {
  echo "❌ Error: $1" >&2
  exit 1
}

# === XcodeGen ===
# プロジェクト生成 (アーカイブ時 or ビルドありテスト実行時)
if [[ "$run_test_without_building" = false && ( "$run_archive" = true || "$run_unit_tests" = true || "$run_ui_tests" = true ) ]]; then
  step "Generating Xcode project using XcodeGen"
  # mint確認
  if ! command -v mint &> /dev/null; then
      fail "Mint is not installed. Please install mint first. (brew install mint)"
  fi
  # xcodegen確認 (なければ bootstrap)
  if ! mint list | grep -q 'XcodeGen'; then
      echo "XcodeGen not found via mint. Running 'mint bootstrap'..."
      mint bootstrap || fail "Failed to bootstrap mint packages."
  fi
  echo "Running xcodegen..."
  mint run xcodegen || fail "XcodeGen failed to generate the project."
  # プロジェクトファイル確認
  if [ ! -d "$PROJECT_FILE" ]; then
    fail "Xcode project file '$PROJECT_FILE' not found after running xcodegen."
  fi
  success "Xcode project generated successfully."
fi

# === メイン処理 ===

# 出力ディレクトリ初期化
if [ "$run_test_without_building" = false ]; then
  # 通常実行時: 全てクリーンアップ
  step "Cleaning previous outputs and creating directories"
  echo "Removing old $OUTPUT_DIR directory if it exists..."
  rm -rf "$OUTPUT_DIR"
  echo "Creating directories..."
  mkdir -p "$TEST_RESULTS_DIR/unit" "$TEST_RESULTS_DIR/ui" \
           "$TEST_BUILD_DERIVED_DATA_DIR" \
           "$ARCHIVE_DIR" "$PRODUCTION_DERIVED_DATA_DIR" "$EXPORT_DIR"
  success "Directories created under $OUTPUT_DIR."
else
  # --test-without-building 時: TestResultsのみクリーンアップ
  step "Cleaning previous test results (keeping DerivedData)"
  echo "Removing old test result directories..."
  rm -rf "$TEST_RESULTS_DIR/unit" "$TEST_RESULTS_DIR/ui"
  echo "Creating test result directories..."
  mkdir -p "$TEST_RESULTS_DIR/unit" "$TEST_RESULTS_DIR/ui"
  # DerivedDataの存在確認
  if [ ! -d "$TEST_BUILD_DERIVED_DATA_DIR" ]; then
      fail "DerivedData directory '$TEST_BUILD_DERIVED_DATA_DIR' not found. Run a build first (e.g., without --test-without-building, or with --all-tests)."
  fi
  success "Test result directories cleaned. Using existing DerivedData."
fi

# === テスト実行 ===
if [ "$run_unit_tests" = true ] || [ "$run_ui_tests" = true ]; then
  step "Running Tests"

  # シミュレータ検索 (テスト実行時には常に必要)
  echo "Finding simulator..."
  FIND_SIMULATOR_SCRIPT="./.github/scripts/find-simulator.sh"

  # find-simulator.sh に実行権限付与
  if [ ! -x "$FIND_SIMULATOR_SCRIPT" ]; then
    echo "Making $FIND_SIMULATOR_SCRIPT executable..."
    chmod +x "$FIND_SIMULATOR_SCRIPT"
    if [ $? -ne 0 ]; then
        fail "Failed to make $FIND_SIMULATOR_SCRIPT executable."
    fi
  fi

  # シミュレータID取得
  SIMULATOR_ID=$("$FIND_SIMULATOR_SCRIPT")
  SCRIPT_EXIT_CODE=$?

  if [ $SCRIPT_EXIT_CODE -ne 0 ]; then
      fail "$FIND_SIMULATOR_SCRIPT failed with exit code $SCRIPT_EXIT_CODE."
  fi

  if [ -z "$SIMULATOR_ID" ]; then
    fail "Could not find a suitable simulator ($FIND_SIMULATOR_SCRIPT returned empty ID)."
  fi
  echo "Using Simulator ID: $SIMULATOR_ID"
  success "Simulator selected."

  # Build for Testing (ビルドなしテストの場合はスキップ)
  if [ "$run_test_without_building" = false ]; then
    echo "Building for testing..."
    if [ "$run_unit_tests" = true ]; then
      echo "Building for Unit Tests ($UNIT_TEST_SCHEME)..."
      set -o pipefail && xcodebuild build-for-testing \
        -project "$PROJECT_FILE" \
        -scheme "$UNIT_TEST_SCHEME" \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -derivedDataPath "$TEST_BUILD_DERIVED_DATA_DIR" \
      | xcbeautify || fail "Build for unit testing failed."
    fi
    if [ "$run_ui_tests" = true ]; then
      echo "Building for UI Tests ($UI_TEST_SCHEME)..."
      set -o pipefail && xcodebuild build-for-testing \
        -project "$PROJECT_FILE" \
        -scheme "$UI_TEST_SCHEME" \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -derivedDataPath "$TEST_BUILD_DERIVED_DATA_DIR" \
      | xcbeautify || fail "Build for UI testing failed."
    fi
    success "Build for testing completed."
  else
      echo "Skipping build-for-testing because --test-without-building was specified."
      # ここでDerivedData内の必要なファイル（.xctestrunなど）の存在をより詳細にチェックすることも可能
  fi

  # Unitテスト (xcodebuild test-without-building を使用)
  if [ "$run_unit_tests" = true ]; then
    echo "Running Unit Tests (without building)..."
    set -o pipefail && xcodebuild test-without-building \
      -project "$PROJECT_FILE" \
      -scheme "$UNIT_TEST_SCHEME" \
      -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$TEST_BUILD_DERIVED_DATA_DIR" \
      -enableCodeCoverage NO \
      -resultBundlePath "$TEST_RESULTS_DIR/unit/TestResults.xcresult" \
    | xcbeautify --report junit --report-path "$TEST_RESULTS_DIR/unit/junit.xml"

    # 結果確認
    echo "Verifying unit test results bundle..."
    if [ ! -d "$TEST_RESULTS_DIR/unit/TestResults.xcresult" ]; then
      fail "Unit test result bundle not found at $TEST_RESULTS_DIR/unit/TestResults.xcresult"
    fi
    success "Unit test result bundle found at $TEST_RESULTS_DIR/unit/TestResults.xcresult"
  fi

  # UIテスト (xcodebuild test-without-building を使用)
  if [ "$run_ui_tests" = true ]; then
    echo "Running UI Tests (without building)..."
    set -o pipefail && xcodebuild test-without-building \
      -project "$PROJECT_FILE" \
      -scheme "$UI_TEST_SCHEME" \
      -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$TEST_BUILD_DERIVED_DATA_DIR" \
      -enableCodeCoverage NO \
      -resultBundlePath "$TEST_RESULTS_DIR/ui/TestResults.xcresult" \
    | xcbeautify --report junit --report-path "$TEST_RESULTS_DIR/ui/junit.xml"

    # 結果確認
    echo "Verifying UI test results bundle..."
    if [ ! -d "$TEST_RESULTS_DIR/ui/TestResults.xcresult" ]; then
      fail "UI test result bundle not found at $TEST_RESULTS_DIR/ui/TestResults.xcresult"
    fi
    success "UI test result bundle found at $TEST_RESULTS_DIR/ui/TestResults.xcresult"
  fi
fi

# === アーカイブ ===
# run_archive が true かつ ビルドなしテストでない場合のみ実行
if [ "$run_archive" = true ] && [ "$run_test_without_building" = false ]; then
  step "Building for Production (Unsigned)"

  ARCHIVE_PATH="$ARCHIVE_DIR/TieredGridLayout.xcarchive"
  ARCHIVE_APP_PATH="$ARCHIVE_PATH/Products/Applications/$APP_SCHEME.app"

  # アーカイブ実行
  echo "Building archive..."
  set -o pipefail && xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$APP_SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$ARCHIVE_PATH" \
    -derivedDataPath "$PRODUCTION_DERIVED_DATA_DIR" \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO \
    archive \
  | xcbeautify
  success "Archive build completed."

  # アーカイブ検証
  echo "Verifying archive contents..."
  if [ ! -d "$ARCHIVE_APP_PATH" ]; then
    echo "Error: '$APP_SCHEME.app' not found in expected archive location ($ARCHIVE_APP_PATH)."
    echo "--- Listing Archive Contents (on error) ---"
    ls -lR "$ARCHIVE_PATH" || echo "Archive directory not found or empty."
    fail "Archive verification failed."
  fi
  success "Archive content verified."
fi

step "Local CI Check Completed Successfully!"