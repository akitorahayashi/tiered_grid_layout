#!/bin/bash
set -euo pipefail

# === 設定 ===
OUTPUT_DIR="ci-outputs"
TEST_RESULTS_DIR="$OUTPUT_DIR/test-results"
PACKAGE_TEST_RESULTS_DIR="$TEST_RESULTS_DIR/package"
UI_TEST_RESULTS_DIR="$TEST_RESULTS_DIR/ui"
# TEST_BUILD_DERIVED_DATA_DIR はUIテストビルドとテスト実行で共有
TEST_BUILD_DERIVED_DATA_DIR="$TEST_RESULTS_DIR/DerivedData" # UIテストビルド成果物を格納
PRODUCTION_DIR="$OUTPUT_DIR/production"
ARCHIVE_DIR="$PRODUCTION_DIR/archives"
PRODUCTION_DERIVED_DATA_DIR="$ARCHIVE_DIR/DerivedData" # アーカイブビルド用
EXPORT_DIR="$PRODUCTION_DIR/Export"
PROJECT_FILE="SampleApp.xcodeproj" # UIテストとアーカイブで使用
APP_SCHEME="SampleApp" # アーカイブで使用
UI_TEST_SCHEME="TieredGridLayoutUITests"

# === フラグ ===
run_package_tests=false
run_ui_tests=false
run_archive=false
run_test_without_building=false # UIテスト用
run_all_tests=false # --all-tests 用フラグ (package + UI)
run_all_ci_steps=true # デフォルト: 全CIステップ (packageテスト, UIテスト, アーカイブ)

# === 引数解析 ===
specific_action_requested=false
only_testing_requested=false # --package-test, --ui-test, または --all-tests のみ指定時にtrue

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --test-without-building)
      run_test_without_building=true
      run_archive=false # ビルドなしテストではアーカイブしない
      run_all_ci_steps=false
      specific_action_requested=true
      shift
      ;;
    --all-tests)
      run_package_tests=true
      run_ui_tests=true
      run_all_tests=true # --all-tests が明示的に要求されたことを示す
      run_archive=false
      run_all_ci_steps=false
      specific_action_requested=true
      only_testing_requested=true
      shift
      ;;
    --package-test)
      run_package_tests=true
      run_archive=false
      run_all_ci_steps=false
      specific_action_requested=true
      only_testing_requested=true
      shift
      ;;
    --ui-test)
      run_ui_tests=true
      run_archive=false
      run_all_ci_steps=false
      specific_action_requested=true
      only_testing_requested=true
      shift
      ;;
    --archive-only)
      if [ "$run_test_without_building" = true ]; then
        echo "Error: --test-without-building cannot be used with --archive-only."
        exit 1
      fi
      run_package_tests=false # Archive only does not run tests
      run_ui_tests=false
      run_archive=true
      run_all_ci_steps=false
      specific_action_requested=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# 引数なしなら全CIステップ実行 (package test, ui test, archive)
if [ "$specific_action_requested" = false ]; then
  run_package_tests=true
  run_ui_tests=true
  run_archive=true
  run_test_without_building=false
fi

# --test-without-building が指定されたが、--ui-test がない場合、UIテストを実行
# (packageテストは常にビルドするため、このフラグは主にUIテスト用)
if [ "$run_test_without_building" = true ] && [ "$run_ui_tests" = false ] && [ "$run_all_tests" = false ] ; then
    # If --test-without-building is given, but no specific test type that supports it is mentioned
    # (and not --all-tests which would imply UI tests), assume UI test.
    # --test-without-building が指定され、対応する特定のテストタイプが指定されていない場合
    # (かつ --all-tests でもない場合)、UIテストを想定する。
    if [ "$only_testing_requested" = false ] || [ "$run_package_tests" = false ]; then
        echo "--test-without-building specified; assuming UI tests are intended if not otherwise specified."
        run_ui_tests=true
    fi
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

# === XcodeGen (UIテスト用またはアーカイブ用) ===
# プロジェクト生成 (アーカイブ時 or (ビルドありUIテスト実行時) )
if [[ "$run_test_without_building" = false && ( "$run_archive" = true || "$run_ui_tests" = true ) ]]; then
  step "Generating Xcode project for UI Tests/Archive using XcodeGen"
  if ! command -v mint >/dev/null 2>&1; then
      fail "Mint is not installed. Please install mint first. (brew install mint)"
  fi
  if ! mint list | grep -q -E '(XcodeGen|xcodegen)'; then # XcodeGen/xcodegen両方のケースに対応
      echo "XcodeGen not found via mint. Running 'mint bootstrap'..."
      mint bootstrap || fail "Failed to bootstrap mint packages."
  fi
  echo "Running xcodegen..."
  mint run xcodegen generate || fail "XcodeGen failed to generate the project $PROJECT_FILE."
  if [ ! -d "$PROJECT_FILE" ]; then
    fail "Xcode project file \'$PROJECT_FILE\' not found after running xcodegen."
  fi
  success "Xcode project $PROJECT_FILE generated successfully."
fi

# === メイン処理 ===

# 出力ディレクトリ初期化
if [ "$run_test_without_building" = false ]; then
  step "Cleaning previous outputs and creating directories"
  echo "Removing old $OUTPUT_DIR directory if it exists..."
  rm -rf "$OUTPUT_DIR"
  echo "Creating directories..."
  mkdir -p "$PACKAGE_TEST_RESULTS_DIR" "$UI_TEST_RESULTS_DIR" \
           "$TEST_BUILD_DERIVED_DATA_DIR" \
           "$ARCHIVE_DIR" "$PRODUCTION_DERIVED_DATA_DIR" "$EXPORT_DIR"
  success "Directories created under $OUTPUT_DIR."
else
  # --test-without-building 時: UI TestResultsのみクリーンアップ
  step "Cleaning previous UI test results (keeping UI Test DerivedData)"
  echo "Removing old UI test result directory $UI_TEST_RESULTS_DIR..."
  rm -rf "$UI_TEST_RESULTS_DIR"
  echo "Creating UI test result directory $UI_TEST_RESULTS_DIR..."
  mkdir -p "$UI_TEST_RESULTS_DIR"
  # DerivedDataの存在確認 (UIテスト用)
  if [ "$run_ui_tests" = true ] && [ ! -d "$TEST_BUILD_DERIVED_DATA_DIR" ]; then
      fail "UI Test DerivedData directory \'$TEST_BUILD_DERIVED_DATA_DIR\' not found. Run a build for UI tests first (e.g., without --test-without-building, or with --ui-test)."
  fi
  success "UI test result directories cleaned. Using existing UI Test DerivedData if applicable."
fi

# === Swift Package テスト実行 ===
if [ "$run_package_tests" = true ]; then
  step "Running Swift Package Tests"
  echo "Building Swift Package..."
  if ! swift build; then
    fail "Swift Package build failed."
  fi
  success "Swift Package built successfully."

  echo "Testing Swift Package..."
  # Output XUnit report to specified directory
  # 指定ディレクトリにXUnitレポートを出力
  if ! swift test --xunit-output "$PACKAGE_TEST_RESULTS_DIR/results.xml"; then
    # Allow script to continue to report failure, rather than exit here
    # ここで終了せず、スクリプトが失敗を報告し続けるようにする
    echo "⚠️ Swift Package tests failed. See results in $PACKAGE_TEST_RESULTS_DIR/results.xml"
  else
    success "Swift Package tests completed. Results in $PACKAGE_TEST_RESULTS_DIR/results.xml"
  fi
fi

# === UIテスト実行 ===
if [ "$run_ui_tests" = true ]; then
  step "Running UI Tests"

  echo "Finding simulator for UI Tests..."
  FIND_SIMULATOR_SCRIPT="./.github/scripts/find-simulator.sh"
  if [ ! -x "$FIND_SIMULATOR_SCRIPT" ]; then
    echo "Making $FIND_SIMULATOR_SCRIPT executable..."
    chmod +x "$FIND_SIMULATOR_SCRIPT" || fail "Failed to make $FIND_SIMULATOR_SCRIPT executable."
  fi

  SIMULATOR_ID=$("$FIND_SIMULATOR_SCRIPT")
  SCRIPT_EXIT_CODE=$?
  if [ $SCRIPT_EXIT_CODE -ne 0 ]; then
      fail "$FIND_SIMULATOR_SCRIPT failed with exit code $SCRIPT_EXIT_CODE."
  fi
  if [ -z "$SIMULATOR_ID" ]; then
    fail "Could not find a suitable simulator ($FIND_SIMULATOR_SCRIPT returned empty ID)."
  fi
  echo "Using Simulator ID: $SIMULATOR_ID for UI Tests"
  success "Simulator selected for UI Tests."

  # Build for UI Testing (ビルドなしテストの場合はスキップ)
  if [ "$run_test_without_building" = false ]; then
    echo "Building for UI Testing ($UI_TEST_SCHEME)..."
    # shellcheck disable=SC2086
    xcodebuild build-for-testing \
      -project "$PROJECT_FILE" \
      -scheme "$UI_TEST_SCHEME" \
      -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
      -derivedDataPath "./$TEST_BUILD_DERIVED_DATA_DIR" \
      -configuration Debug \
      CODE_SIGNING_ALLOWED=NO \
      ENABLE_CODE_COVERAGE=NO \
      | xcbeautify || fail "Build for UI Testing ($UI_TEST_SCHEME) failed."
    success "Build for UI Testing ($UI_TEST_SCHEME) complete."
  else
    echo "Skipping build for UI Testing, using existing DerivedData: $TEST_BUILD_DERIVED_DATA_DIR"
  fi

  echo "Running UI Tests ($UI_TEST_SCHEME)..."
  # shellcheck disable=SC2086
  xcodebuild test-without-building \
    -project "$PROJECT_FILE" \
    -scheme "$UI_TEST_SCHEME" \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -derivedDataPath "./$TEST_BUILD_DERIVED_DATA_DIR" \
    -resultBundlePath "./$UI_TEST_RESULTS_DIR/TestResults.xcresult" \
    | xcbeautify --report junit --report-path "./$UI_TEST_RESULTS_DIR/junit.xml"

  # xcbeautify might swallow the exit code, check .xcresult existence and content as a proxy
  # xcbeautifyが終了コードを隠蔽する場合があるため、.xcresultの存在と内容を代わりに確認
  if [ ! -d "./$UI_TEST_RESULTS_DIR/TestResults.xcresult" ]; then
    echo "⚠️ UI tests for $UI_TEST_SCHEME failed or did not produce results. No .xcresult bundle found."
  elif ! grep -q \'\<string\>Tests Succeeded\</string\>\' "./$UI_TEST_RESULTS_DIR/TestResults.xcresult/Info.plist"; then
    echo "⚠️ UI tests for $UI_TEST_SCHEME likely failed. Check ./$UI_TEST_RESULTS_DIR"
  else
    success "UI Tests ($UI_TEST_SCHEME) completed. Results in $UI_TEST_RESULTS_DIR"
  fi
  ls -la "./$UI_TEST_RESULTS_DIR/"
fi


# === アーカイブビルド ===
if [ "$run_archive" = true ]; then
  step "Running Archive Build"

  # Check if project file exists (might not if only package tests were run before this)
  # プロジェクトファイルの存在確認 (前にpackageテストのみ実行された場合は存在しない可能性あり)
  if [ ! -d "$PROJECT_FILE" ]; then
    fail "Xcode project file \'$PROJECT_FILE\' not found. It's needed for archiving. Ensure XcodeGen has run or run with an option that generates it (e.g. --ui-test or default)."
  fi

  echo "Building archive ($APP_SCHEME)..."
  # shellcheck disable=SC2086
  xcodebuild archive \
    -project "$PROJECT_FILE" \
    -scheme "$APP_SCHEME" \
    -configuration Release \
    -derivedDataPath "./$PRODUCTION_DERIVED_DATA_DIR" \
    -archivePath "./$ARCHIVE_DIR/$APP_SCHEME.xcarchive" \
    CODE_SIGNING_ALLOWED=NO \
    SKIP_INSTALL=NO \
    | xcbeautify || fail "Archive build for $APP_SCHEME failed."

  success "Archive created successfully at $ARCHIVE_DIR/$APP_SCHEME.xcarchive"

  # Verify archive (basic check)
  # アーカイブ検証 (基本チェック)
  if [ ! -d "$ARCHIVE_DIR/$APP_SCHEME.xcarchive" ]; then
    fail "Archive verification failed: $ARCHIVE_DIR/$APP_SCHEME.xcarchive not found."
  fi
  echo "Archive content basic check:"
  ls -R "$ARCHIVE_DIR/$APP_SCHEME.xcarchive"
  success "Archive verification passed (basic check)."
fi

echo ""
echo "──────────────────────────────────────────────────────────────────────"
echo "✅ Local CI script finished."
echo "──────────────────────────────────────────────────────────────────────"