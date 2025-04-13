//
//  TieredGridLayoutUITests.swift
//  TieredGridLayoutUITests
//
//  Created by akitora.hayashi on 2025/04/13.
//

import XCTest

final class TieredGridLayoutUITests: XCTestCase {

    override func setUpWithError() throws {
        // テスト実行前の準備コードをここに記述します
        
        // UIテストでは、エラー発生時に即座に停止することが通常は最適です
        continueAfterFailure = false
        
        // UIテストでは、実行前に必要な初期状態（画面の向きなど）を設定することが重要です
    }

    override func tearDownWithError() throws {
        // テスト実行後のクリーンアップコードをここに記述します
    }

    @MainActor
    func testグリッドレイアウトの存在確認() throws {
        // テスト対象のアプリケーションを起動します
        let app = XCUIApplication()
        app.launch()
        
        // グリッドレイアウトが存在し、表示されていることを確認します
        let gridLayout = app.otherElements["tieredGridLayout"]
        XCTAssertTrue(gridLayout.exists, "TieredGridLayoutがビュー階層に存在する必要があります")
        XCTAssertTrue(gridLayout.isHittable, "TieredGridLayoutが画面上で見えている必要があります")
    }
    
    @MainActor
    func testグリッドアイテムの操作() throws {
        let app = XCUIApplication()
        app.launch()
        
        // グリッドアイテムが存在するか確認します
        let gridItems = app.otherElements.matching(identifier: "gridItem")
        XCTAssertGreaterThan(gridItems.count, 0, "グリッドには少なくとも1つのアイテムが必要です")
        
        // グリッドアイテムとの対話をテストします
        if !gridItems.isEmpty {
            let firstItem = gridItems.element(boundBy: 0)
            XCTAssertTrue(firstItem.exists, "最初のグリッドアイテムが存在する必要があります")
            firstItem.tap()
            
            // タップ操作の結果を確認します（例：詳細ビューが表示される）
            let detailView = app.otherElements["itemDetailView"]
            XCTAssertTrue(detailView.waitForExistence(timeout: 2), "グリッドアイテムをタップすると詳細ビューが表示されるべきです")
        }
    }
    
    @MainActor
    func testグリッドのスクロール機能() throws {
        let app = XCUIApplication()
        app.launch()
        
        // レイアウトがスクロールビュー内にある場合のスクロールをテストします
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // スクロールを確認するためにアイテムの初期位置を取得します
            let beforeScroll = app.otherElements["gridItem"].firstMatch.frame
            
            // 下方向へのスクロールを実行します
            scrollView.swipeUp()
            
            // スクロールが発生したことを確認します
            let afterScroll = app.otherElements["gridItem"].firstMatch.frame
            XCTAssertNotEqual(beforeScroll, afterScroll, "グリッドは垂直方向にスクロールできるはずです")
        }
    }

    @MainActor
    func test起動パフォーマンス() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // アプリケーションの起動にかかる時間を測定します
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
