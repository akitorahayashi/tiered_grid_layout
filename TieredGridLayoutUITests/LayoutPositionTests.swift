import XCTest

final class LayoutPositionTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [LaunchArgument.uiTesting.rawValue]
        app.launch()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
        try super.tearDownWithError()
    }

    var screenSize: CGSize {
        guard let window = app?.windows.firstMatch else {
            XCTFail("アプリケーションウィンドウが見つかりません")
            return .zero
        }
        return window.frame.size
    }

    let frameTolerance: CGFloat = 5.0

    // 初期状態（アイテム5個）でコンテナとアイテムが存在することを確認する。
    func testInitialLayout() throws {
        let gridContainer = app.scrollViews[AccessibilityID.gridContainer.rawValue]
        XCTAssertTrue(gridContainer.waitForExistence(timeout: 2), "グリッドコンテナ (ScrollView) が存在する")

        for i in 0 ..< 5 {
            let item = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: i)]
            XCTAssertTrue(item.waitForExistence(timeout: 1), "アイテム \\(i) が表示されている")
        }
    }

    // 特定のキーアイテム間の相対的な位置とサイズの関係性を検証する。
    func testItemFrames() throws {
        let increaseButton = app.buttons[AccessibilityID.increaseButton.rawValue]
        for _ in 5 ..< 10 {
            increaseButton.tap()
        }

        let gridContainer = app.scrollViews[AccessibilityID.gridContainer.rawValue]
        XCTAssertTrue(gridContainer.waitForExistence(timeout: 2))

        let item0 = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: 0)]
        let item1 = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: 1)]
        let item2 = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: 2)]
        let item3 = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: 3)] // 2x2 アイテム
        let item4 = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: 4)]
        let item9 = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: 9)] // 3x3 アイテム

        XCTAssertTrue(item0.waitForExistence(timeout: 2))
        XCTAssertTrue(item1.waitForExistence(timeout: 2))
        XCTAssertTrue(item2.waitForExistence(timeout: 2))
        XCTAssertTrue(item3.waitForExistence(timeout: 2))
        XCTAssertTrue(item4.waitForExistence(timeout: 2))
        XCTAssertTrue(item9.waitForExistence(timeout: 2))

        let frame0 = item0.frame
        let frame1 = item1.frame
        let frame2 = item2.frame
        let frame3 = item3.frame
        let frame4 = item4.frame
        let frame9 = item9.frame
        let screenWidth = screenSize.width

        // 位置チェック
        XCTAssertEqual(frame0.minX, gridContainer.frame.minX, accuracy: frameTolerance, "アイテム 0 の X 座標はコンテナの左端に近接する")
        XCTAssertEqual(frame0.minY, gridContainer.frame.minY, accuracy: frameTolerance, "アイテム 0 の Y 座標はコンテナの上端に近接する")
        XCTAssertGreaterThan(frame3.minY, frame0.maxY - frameTolerance, "アイテム 3 はアイテム 0 の下にある")
        XCTAssertGreaterThan(frame9.minY, frame3.maxY - frameTolerance, "アイテム 9 はアイテム 3 の下にある")
        XCTAssertGreaterThan(frame1.minX, frame0.maxX - frameTolerance, "アイテム 1 はアイテム 0 の右にある")
        XCTAssertGreaterThan(frame2.minX, frame1.maxX - frameTolerance, "アイテム 2 はアイテム 1 の右にある")
        XCTAssertGreaterThan(frame4.minX, frame3.maxX - frameTolerance, "アイテム 4 はアイテム 3 の右にある")

        // サイズチェック
        let unitWidth = screenWidth / 3
        let unitSizeTolerance = unitWidth * 0.1 // ユニット幅に基づく許容誤差
        XCTAssertEqual(frame0.width, unitWidth, accuracy: unitSizeTolerance, "アイテム 0 の幅が不一致")
        XCTAssertEqual(frame3.width, frame0.width * 2, accuracy: unitSizeTolerance * 2, "アイテム 3 の幅はアイテム 0 の約2倍である")
        XCTAssertEqual(frame3.height, frame0.height * 2, accuracy: unitSizeTolerance * 2, "アイテム 3 の高さはアイテム 0 の約2倍である")
        XCTAssertEqual(frame9.width, frame0.width * 3, accuracy: unitSizeTolerance * 3, "アイテム 9 の幅はアイテム 0 の約3倍である")
        XCTAssertEqual(frame9.height, frame0.height * 3, accuracy: unitSizeTolerance * 3, "アイテム 9 の高さはアイテム 0 の約3倍である")
    }

    // アイテム10個（1パターン分）の絶対的な位置とサイズが期待通りか検証する。
    func testFullLayoutPatternPositions() throws {
        // アイテム数が正確に10個になるようにする（初期5個 + 追加5個）
        let increaseButton = app.buttons[AccessibilityID.increaseButton.rawValue]
        for _ in 0 ..< 5 {
            increaseButton.tap()
        }

        let gridContainer = app.scrollViews[AccessibilityID.gridContainer.rawValue]
        XCTAssertTrue(gridContainer.waitForExistence(timeout: 2))

        var items: [XCUIElement] = []
        for i in 0 ..< 10 {
            let item = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: i)]
            XCTAssertTrue(item.waitForExistence(timeout: 1))
            items.append(item)
        }

        let frames = items.map(\.frame)

        guard !frames.isEmpty else {
            XCTFail("アイテムのフレームが取得できませんでした")
            return
        }
        let containerFrame = gridContainer.frame // frame は non-optional

        let containerX = containerFrame.minX
        let containerY = containerFrame.minY
        let unitWidth = containerFrame.width / 3
        let tolerance = unitWidth * 0.1 // ユニット幅に基づく許容誤差

        // 期待されるレイアウトパターン（ユニット単位）
        struct LayoutPatternItem {
            let x, y: CGFloat
            let width, height: CGFloat // w -> width, h -> height
        }
        // 期待されるレイアウトパターン（ユニット単位）
        let pattern: [LayoutPatternItem] = [
            LayoutPatternItem(x: 0, y: 0, width: 1, height: 1), // 0
            LayoutPatternItem(x: 1, y: 0, width: 1, height: 1), // 1
            LayoutPatternItem(x: 2, y: 0, width: 1, height: 1), // 2
            LayoutPatternItem(x: 0, y: 1, width: 2, height: 2), // 3
            LayoutPatternItem(x: 2, y: 1, width: 1, height: 1), // 4
            LayoutPatternItem(x: 2, y: 2, width: 1, height: 1), // 5
            LayoutPatternItem(x: 0, y: 3, width: 1, height: 1), // 6
            LayoutPatternItem(x: 1, y: 3, width: 1, height: 1), // 7
            LayoutPatternItem(x: 2, y: 3, width: 1, height: 1), // 8
            LayoutPatternItem(x: 0, y: 4, width: 3, height: 3), // 9
        ]

        for index in 0 ..< 10 {
            let expected = pattern[index]
            let actualFrame = frames[index]

            let expectedX = containerX + expected.x * unitWidth
            let expectedY = containerY + expected.y * unitWidth
            let expectedW = expected.width * unitWidth // expected.w -> expected.width
            let expectedH = expected.height * unitWidth // expected.h -> expected.height

            XCTAssertEqual(actualFrame.minX, expectedX, accuracy: tolerance, "アイテム \\(index) の minX 位置が不一致")
            XCTAssertEqual(actualFrame.minY, expectedY, accuracy: tolerance, "アイテム \\(index) の minY 位置が不一致")
            XCTAssertEqual(actualFrame.width, expectedW, accuracy: tolerance, "アイテム \\(index) の幅が不一致")
            XCTAssertEqual(actualFrame.height, expectedH, accuracy: tolerance, "アイテム \\(index) の高さが不一致")
        }
    }
}
