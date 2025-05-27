import XCTest
import TieredGridLayout

final class LayoutPositionTests: XCTestCase {
    var app: XCUIApplication!
    var gridContainer: XCUIElement!
    var increaseButton: XCUIElement!
    var unitWidth: CGFloat!
    var tolerance: CGFloat!
    var containerX: CGFloat!
    var containerY: CGFloat!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [LaunchArgument.uiTesting.rawValue]
        app.launch()

        // 共通のUI要素を取得
        gridContainer = app.scrollViews[AccessibilityID.gridContainer.rawValue]
        increaseButton = app.buttons[AccessibilityID.increaseButton.rawValue]

        // コンテナの存在を確認
        XCTAssertTrue(gridContainer.waitForExistence(timeout: 2), "グリッドコンテナ (ScrollView) が存在する")

        // レイアウト計算に必要な値を設定
        let containerFrame = gridContainer.frame
        containerX = containerFrame.minX
        containerY = containerFrame.minY
        unitWidth = containerFrame.width / 3
        tolerance = unitWidth * 0.1
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
        gridContainer = nil
        increaseButton = nil
        try super.tearDownWithError()
    }

    // 指定された数のアイテムが存在することを確認し、そのフレーム（位置とサイズ）を取得
    func verifyAndGetItemFrames(count: Int) -> [CGRect] {
        var items: [XCUIElement] = []
        for i in 0 ..< count {
            let item = gridContainer.descendants(matching: .any)[AccessibilityID.item(index: i)]
            XCTAssertTrue(item.waitForExistence(timeout: 1), "アイテム \(i) が表示されている")
            items.append(item)
        }
        return items.map(\.frame)
    }

    // レイヤーの種類に応じて、アイテムの位置とサイズが正しいことを検証
    func verifyLayerItems(layer: TGLayer, frames: [CGRect], startIndex: Int, currentY: CGFloat) -> Int {
        var itemIndex = startIndex
        switch layer {
        case .threeSmall:
            // 3つの小アイテムを横に配置
            for x in 0..<3 {
                let frame = frames[itemIndex]
                XCTAssertEqual(frame.minX, containerX + CGFloat(x) * unitWidth, accuracy: tolerance)
                XCTAssertEqual(frame.minY, containerY + currentY * unitWidth, accuracy: tolerance)
                XCTAssertEqual(frame.width, unitWidth, accuracy: tolerance)
                XCTAssertEqual(frame.height, unitWidth, accuracy: tolerance)
                itemIndex += 1
            }
        case .mediumWithTwoSmall(let mediumOnLeft):
            if mediumOnLeft {
                // 中アイテム（左）と2つの小アイテム（右）
                let mediumFrame = frames[itemIndex]
                XCTAssertEqual(mediumFrame.minX, containerX, accuracy: tolerance)
                XCTAssertEqual(mediumFrame.minY, containerY + currentY * unitWidth, accuracy: tolerance)
                XCTAssertEqual(mediumFrame.width, unitWidth * 2, accuracy: tolerance)
                XCTAssertEqual(mediumFrame.height, unitWidth * 2, accuracy: tolerance)
                itemIndex += 1

                // 2つの小アイテム
                for y in 0..<2 {
                    let frame = frames[itemIndex]
                    XCTAssertEqual(frame.minX, containerX + unitWidth * 2, accuracy: tolerance)
                    XCTAssertEqual(frame.minY, containerY + (currentY + CGFloat(y)) * unitWidth, accuracy: tolerance)
                    XCTAssertEqual(frame.width, unitWidth, accuracy: tolerance)
                    XCTAssertEqual(frame.height, unitWidth, accuracy: tolerance)
                    itemIndex += 1
                }
            } else {
                // 2つの小アイテム（左）と中アイテム（右）
                for y in 0..<2 {
                    let frame = frames[itemIndex]
                    XCTAssertEqual(frame.minX, containerX, accuracy: tolerance)
                    XCTAssertEqual(frame.minY, containerY + (currentY + CGFloat(y)) * unitWidth, accuracy: tolerance)
                    XCTAssertEqual(frame.width, unitWidth, accuracy: tolerance)
                    XCTAssertEqual(frame.height, unitWidth, accuracy: tolerance)
                    itemIndex += 1
                }

                let mediumFrame = frames[itemIndex]
                XCTAssertEqual(mediumFrame.minX, containerX + unitWidth, accuracy: tolerance)
                XCTAssertEqual(mediumFrame.minY, containerY + currentY * unitWidth, accuracy: tolerance)
                XCTAssertEqual(mediumFrame.width, unitWidth * 2, accuracy: tolerance)
                XCTAssertEqual(mediumFrame.height, unitWidth * 2, accuracy: tolerance)
                itemIndex += 1
            }
        case .oneLarge:
            // 1つの大アイテム
            let frame = frames[itemIndex]
            XCTAssertEqual(frame.minX, containerX, accuracy: tolerance)
            XCTAssertEqual(frame.minY, containerY + currentY * unitWidth, accuracy: tolerance)
            XCTAssertEqual(frame.width, unitWidth * 3, accuracy: tolerance)
            XCTAssertEqual(frame.height, unitWidth * 3, accuracy: tolerance)
            itemIndex += 1
        }
        return itemIndex
    }

    // 初期状態（アイテム5個）でコンテナとアイテムが存在することを確認
    func testInitialLayout() throws {
        _ = verifyAndGetItemFrames(count: 5)
    }

    // 特定のキーアイテム間の相対的な位置とサイズの関係性を検証
    func testItemFrames() throws {
        // アイテムを10個に増やす
        for _ in 5 ..< 10 {
            increaseButton.tap()
        }

        let frames = verifyAndGetItemFrames(count: 10)
        let frame0 = frames[0]
        let frame1 = frames[1]
        let frame2 = frames[2]
        let frame3 = frames[3]
        let frame4 = frames[4]
        let frame9 = frames[9]

        // 位置をチェック
        XCTAssertEqual(frame0.minX, gridContainer.frame.minX, accuracy: tolerance, "アイテム 0 の X 座標はコンテナの左端に近接する")
        XCTAssertEqual(frame0.minY, gridContainer.frame.minY, accuracy: tolerance, "アイテム 0 の Y 座標はコンテナの上端に近接する")
        XCTAssertGreaterThan(frame3.minY, frame0.maxY - tolerance, "アイテム 3 はアイテム 0 の下にある")
        XCTAssertGreaterThan(frame9.minY, frame3.maxY - tolerance, "アイテム 9 はアイテム 3 の下にある")
        XCTAssertGreaterThan(frame1.minX, frame0.maxX - tolerance, "アイテム 1 はアイテム 0 の右にある")
        XCTAssertGreaterThan(frame2.minX, frame1.maxX - tolerance, "アイテム 2 はアイテム 1 の右にある")
        XCTAssertGreaterThan(frame4.minX, frame3.maxX - tolerance, "アイテム 4 はアイテム 3 の右にある")

        // サイズをチェック
        XCTAssertEqual(frame0.width, unitWidth, accuracy: tolerance, "アイテム 0 の幅が不一致")
        XCTAssertEqual(frame3.width, frame0.width * 2, accuracy: tolerance * 2, "アイテム 3 の幅はアイテム 0 の約2倍である")
        XCTAssertEqual(frame3.height, frame0.height * 2, accuracy: tolerance * 2, "アイテム 3 の高さはアイテム 0 の約2倍である")
        XCTAssertEqual(frame9.width, frame0.width * 3, accuracy: tolerance * 3, "アイテム 9 の幅はアイテム 0 の約3倍である")
        XCTAssertEqual(frame9.height, frame0.height * 3, accuracy: tolerance * 3, "アイテム 9 の高さはアイテム 0 の約3倍である")
    }

    // レイアウトパターンの検証
    func testLayoutPattern() throws {
        // アイテムを10個に増やす
        for _ in 5 ..< 10 {
            increaseButton.tap()
        }

        let frames = verifyAndGetItemFrames(count: 10)
        let pattern = TGLayoutPattern()
        var currentY: CGFloat = 0
        var itemIndex = 0

        // 各レイヤーのアイテムを検証
        for layer in pattern.layers {
            itemIndex = verifyLayerItems(layer: layer, frames: frames, startIndex: itemIndex, currentY: currentY)
            currentY += layer.unitHeight
        }
    }

    // 大量の要素に対するレイアウトの安定性を検証
    func testLayoutStabilityWithManyItems() throws {
        // アイテムを100個に増やす（10パターン分）
        for _ in 5 ..< 100 {
            increaseButton.tap()
        }

        let frames = verifyAndGetItemFrames(count: 100)
        let pattern = TGLayoutPattern()
        var currentY: CGFloat = 0
        var itemIndex = 0

        // 10パターン分のレイアウトを検証
        for patternIndex in 0..<10 {
            // 各レイヤーのアイテムを検証
            for layer in pattern.layers {
                itemIndex = verifyLayerItems(layer: layer, frames: frames, startIndex: itemIndex, currentY: currentY)
                currentY += layer.unitHeight
            }

            // パターン間の間隔が正しいことを確認
            if patternIndex < 9 { // 最後のパターン以外
                let nextPatternStartY = currentY
                let currentPatternEndY = currentY - pattern.layers.last!.unitHeight
                XCTAssertEqual(nextPatternStartY - currentPatternEndY, 0, accuracy: tolerance,
                             "パターン \(patternIndex) と \(patternIndex + 1) の間の間隔が正しい")
            }
        }

        // スクロールが可能であることを確認
        let initialContentOffset = gridContainer.value(forKey: "contentOffset") as! CGPoint
        gridContainer.swipeUp()
        let scrolledContentOffset = gridContainer.value(forKey: "contentOffset") as! CGPoint
        XCTAssertGreaterThan(scrolledContentOffset.y, initialContentOffset.y,
                           "コンテナがスクロール可能である")

        // スクロール後もレイアウトが維持されていることを確認
        let scrolledFrames = verifyAndGetItemFrames(count: 100)
        for i in 0..<frames.count {
            XCTAssertEqual(frames[i].width, scrolledFrames[i].width, accuracy: tolerance,
                         "スクロール後もアイテム \(i) の幅が維持されている")
            XCTAssertEqual(frames[i].height, scrolledFrames[i].height, accuracy: tolerance,
                         "スクロール後もアイテム \(i) の高さが維持されている")
        }
    }
}
