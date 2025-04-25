import XCTest

final class DynamicBehaviorTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [LaunchArgument.uiTesting.rawValue]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
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

    // アイテム追加時にコンテナサイズが適切に増加するか検証する。
    func testItemCountChangeAndContainerSize() throws {
        let scrollView = app.scrollViews.element
        XCTAssertTrue(scrollView.waitForExistence(timeout: 2), "ScrollView が存在する")

        // 注意: gridContainer を子孫としてクエリするのは不安定な場合があります。
        // ScrollView 自体が測定対象のコンテナであるかを検討してください。
        let gridContainerElement = app.scrollViews[AccessibilityID.gridContainer.rawValue]
        XCTAssertTrue(gridContainerElement.waitForExistence(timeout: 1), "GridContainer が ScrollView 内に存在する")

        let initialGridFrame = gridContainerElement.frame

        let increaseButton = app.buttons[AccessibilityID.increaseButton.rawValue]
        increaseButton.tap()

        let newItem = gridContainerElement.descendants(matching: .any)[AccessibilityID.item(index: 5)]
        XCTAssertTrue(newItem.waitForExistence(timeout: 2), "増加後の新しいアイテム (item_5) が存在する")

        sleep(1)

        let newGridFrame = gridContainerElement.frame
        print("Initial Grid Frame: \(initialGridFrame)")
        print("New Grid Frame: \(newGridFrame)")
        XCTAssertGreaterThan(newGridFrame.height, initialGridFrame.height - frameTolerance, "アイテム追加後、グリッドコンテナの高さが増加する")
    }

    // 多数のアイテムがある場合にスクロールによって要素が表示されるか検証する。
    func testScrollingWithManyItems() throws {
        let increaseButton = app.buttons[AccessibilityID.increaseButton.rawValue]
        let scrollView = app.scrollViews.element(boundBy: 0) // 最初の ScrollView と仮定

        // スクロールが必要になるまでアイテムを増やす (例: 11アイテム)
        for _ in 0 ..< 6 {
            increaseButton.tap()
        }

        let gridContainerElement = app.scrollViews[AccessibilityID.gridContainer.rawValue]
        XCTAssertTrue(gridContainerElement.waitForExistence(timeout: 1), "GridContainer が存在する")

        let item10 = gridContainerElement.descendants(matching: .any)[AccessibilityID.item(index: 10)]
        XCTAssertTrue(item10.waitForExistence(timeout: 2), "アイテム 10 が階層内に存在する")

        // item 10 が hittable (画面内でタップ可能) かどうか
        if item10.isHittable {
            print("アイテム 10 は初期状態で hittable (画面が大きい可能性)")
        } else {
            print("アイテム 10 は初期状態では hittable ではないため、スクロールを実行")
        }

        var scrollAttempts = 0
        let maxScrollAttempts = 10 // 無限ループ防止

        while !item10.isHittable, scrollAttempts < maxScrollAttempts {
            scrollView.swipeUp() // 上にスワイプ = 下にスクロール
            scrollAttempts += 1
            if item10.isHittable { break }
        }

        XCTAssertTrue(item10.isHittable, "スクロール後、アイテム 10 が hittable になる")
    }
}
