#!/bin/bash
set -euo pipefail

# === 設定 ===
OUTPUT_DIR="ci-outputs"
TEST_RESULTS_DIR="$OUTPUT_DIR/test-results"
UNIT_TEST_DERIVED_DATA_DIR="$TEST_RESULTS_DIR/DerivedData/unit"
UI_TEST_DERIVED_DATA_DIR="$TEST_RESULTS_DIR/DerivedData/ui"
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
# skip_build_for_testing は廃止
run_all=true # デフォルト: 全実行

# === 引数解析 ===
specific_action_requested=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --all-tests)
      run_unit_tests=true
      run_ui_tests=true
      run_archive=false
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --unit-test)
      run_unit_tests=true
      run_archive=false
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --ui-test)
      run_ui_tests=true
      run_archive=false
      run_all=false
      specific_action_requested=true
      shift
      ;;
    --archive-only)
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

# 引数なしなら全実行
if [ "$specific_action_requested" = false ]; then
  run_unit_tests=true
  run_ui_tests=true
  run_archive=true
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
# プロジェクト生成 (アーカイブ時のみ or テスト実行時にも必要)
if [ "$run_archive" = true ] || [ "$run_unit_tests" = true ] || [ "$run_ui_tests" = true ]; then
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

# 出力ディレクトリ初期化 (常に実行、DerivedDataパスはテスト/アーカイブで共通利用)
step "Cleaning previous outputs and creating directories"
echo "Removing old $OUTPUT_DIR directory if it exists..."
rm -rf "$OUTPUT_DIR"
echo "Creating directories..."
mkdir -p "$TEST_RESULTS_DIR/unit" "$TEST_RESULTS_DIR/ui" \
         "$UNIT_TEST_DERIVED_DATA_DIR" "$UI_TEST_DERIVED_DATA_DIR" \
         "$ARCHIVE_DIR" "$PRODUCTION_DERIVED_DATA_DIR" "$EXPORT_DIR"
success "Directories created under $OUTPUT_DIR."

# === テスト実行 ===
if [ "$run_unit_tests" = true ] || [ "$run_ui_tests" = true ]; then
  step "Running Tests"

  # シミュレータ検索
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

  # build-for-testing セクションは削除

  # Unitテスト (xcodebuild test を使用)
  if [ "$run_unit_tests" = true ]; then
    echo "Running Unit Tests..."
    set -o pipefail && xcodebuild test \
      -project "$PROJECT_FILE" \
      -scheme "$UNIT_TEST_SCHEME" \
      -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$UNIT_TEST_DERIVED_DATA_DIR" \
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

  # UIテスト (xcodebuild test を使用)
  if [ "$run_ui_tests" = true ]; then
    echo "Running UI Tests..."
    set -o pipefail && xcodebuild test \
      -project "$PROJECT_FILE" \
      -scheme "$UI_TEST_SCHEME" \
      -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "$UI_TEST_DERIVED_DATA_DIR" \
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
if [ "$run_archive" = true ]; then
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