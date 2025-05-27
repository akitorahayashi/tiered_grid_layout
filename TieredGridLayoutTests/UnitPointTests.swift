import SwiftUI
@testable import TieredGridLayout
import XCTest

final class UnitPointTests: XCTestCase {
    var layout: TieredGridLayout!

    override func setUpWithError() throws {
        try super.setUpWithError()
        layout = TieredGridLayout()
    }

    override func tearDownWithError() throws {
        layout = nil
        try super.tearDownWithError()
    }

    func testDefaultAlignment() {
        // TieredGridLayout のデフォルト alignment が .center であることを確認
        let defaultLayout = TieredGridLayout()
        XCTAssertEqual(defaultLayout.alignment, .center, "TieredGridLayout のデフォルト alignment は .center であるべき")
    }

    func testUnhandledAlignment() {
        // 未対応の alignment の場合も .center を返すことを確認
        let defaultLayout = TieredGridLayout()
        let unhandledAlignmentResult = defaultLayout.unitPoint(for: .leadingLastTextBaseline)
        XCTAssertEqual(unhandledAlignmentResult, .center, "未処理の alignment の場合も .center を返すことを確認")
    }

    func testUnitPointMapping() {
        let testCases: [(Alignment, UnitPoint)] = [
            (.topLeading, .topLeading),
            (.top, .top),
            (.topTrailing, .topTrailing),
            (.leading, .leading),
            (.center, .center),
            (.trailing, .trailing),
            (.bottomLeading, .bottomLeading),
            (.bottom, .bottom),
            (.bottomTrailing, .bottomTrailing),
        ]

        for (alignment, expectedUnitPoint) in testCases {
            let result = layout.unitPoint(for: alignment)
            XCTAssertEqual(
                result,
                expectedUnitPoint,
                "Alignment \(alignment) は \(expectedUnitPoint) にマップされることを確認 (実際の結果: \(result))"
            )
        }
    }
}
