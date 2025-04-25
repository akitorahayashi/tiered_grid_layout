import SwiftUI
@testable import TieredGridLayout
import XCTest

final class TieredGridLayoutTests: XCTestCase {
    var layout: TieredGridLayout!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // generatePositions の予測可能性のため、alignment を固定
        layout = TieredGridLayout(alignment: .topLeading)
    }

    override func tearDownWithError() throws {
        layout = nil
        try super.tearDownWithError()
    }

    // MARK: - generatePositions Tests

    func testGeneratePositions_withZeroCount() {
        let positions = layout.generatePositions(count: 0, width: 300)
        XCTAssertTrue(positions.isEmpty, "要素数が0の場合、positionsは空です")
    }

    func testGeneratePositions_withZeroWidth() {
        let positions = layout.generatePositions(count: 5, width: 0)
        XCTAssertTrue(positions.isEmpty, "幅が0の場合、positionsは空です")
    }

    func testGeneratePositions_singleItem() {
        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(count: 1, width: width)

        XCTAssertEqual(positions.count, 1)
        guard positions.count == 1 else { return }

        // Item 0: x=0, y=0, w=1, h=1
        XCTAssertEqual(positions[0].0, CGPoint(x: 0 * unit, y: 0 * unit))
        XCTAssertEqual(positions[0].1, CGSize(width: 1 * unit, height: 1 * unit))
    }

    func testGeneratePositions_multipleItems_lessThanOneSet() {
        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(count: 4, width: width)

        XCTAssertEqual(positions.count, 4)
        guard positions.count == 4 else { return }

        // Item 0
        XCTAssertEqual(positions[0].0, CGPoint(x: 0 * unit, y: 0 * unit))
        XCTAssertEqual(positions[0].1, CGSize(width: 1 * unit, height: 1 * unit))
        // Item 1
        XCTAssertEqual(positions[1].0, CGPoint(x: 1 * unit, y: 0 * unit))
        XCTAssertEqual(positions[1].1, CGSize(width: 1 * unit, height: 1 * unit))
        // Item 2
        XCTAssertEqual(positions[2].0, CGPoint(x: 2 * unit, y: 0 * unit))
        XCTAssertEqual(positions[2].1, CGSize(width: 1 * unit, height: 1 * unit))
        // Item 3
        XCTAssertEqual(positions[3].0, CGPoint(x: 0 * unit, y: 1 * unit))
        XCTAssertEqual(positions[3].1, CGSize(width: 2 * unit, height: 2 * unit))
    }

    func testGeneratePositions_oneFullSet() {
        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(count: 10, width: width)

        XCTAssertEqual(positions.count, 10)
        guard positions.count == 10 else { return }

        // Check last item (Item 9)
        XCTAssertEqual(positions[9].0, CGPoint(x: 0 * unit, y: 4 * unit))
        XCTAssertEqual(positions[9].1, CGSize(width: 3 * unit, height: 3 * unit))
    }

    func testGeneratePositions_moreThanOneSet() {
        let width: CGFloat = 300
        let unit = width / 3
        let setHeightInUnits: CGFloat = 7 // From TieredGridLayout definition
        let setHeight = setHeightInUnits * unit
        let positions = layout.generatePositions(count: 11, width: width) // 1 full set + 1 item

        XCTAssertEqual(positions.count, 11)
        guard positions.count == 11 else { return }

        // Check first item of the second set (Item 10, pattern Item 0)
        XCTAssertEqual(positions[10].0, CGPoint(x: 0 * unit, y: 0 * unit + setHeight))
        XCTAssertEqual(positions[10].1, CGSize(width: 1 * unit, height: 1 * unit))

        // Check another item in the second set (Item 13, pattern Item 3)
        let positions13 = layout.generatePositions(count: 14, width: width) // 1 full set + 4 items
        XCTAssertEqual(positions13[13].0, CGPoint(x: 0 * unit, y: 1 * unit + setHeight))
        XCTAssertEqual(positions13[13].1, CGSize(width: 2 * unit, height: 2 * unit))
    }

    // MARK: - unitPoint Tests

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
                "Alignment \(alignment) は \(expectedUnitPoint) にマップされます (実際の結果: \(result))"
            )
        }

        // Check default case (should be .topLeading as per implementation)
        let defaultCaseResult = layout
            .unitPoint(for: .leadingLastTextBaseline) // Use an alignment not explicitly handled
        XCTAssertEqual(defaultCaseResult, .topLeading, "Alignment のデフォルトケースは .topLeading を返します")
    }
}
