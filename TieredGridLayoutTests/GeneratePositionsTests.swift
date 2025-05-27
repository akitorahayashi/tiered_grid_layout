import SwiftUI
@testable import TieredGridLayout
import XCTest

final class GeneratePositionsTests: XCTestCase {
    private let setHeightInUnits: CGFloat = 7

    var layout: TieredGridLayout!

    override func setUpWithError() throws {
        try super.setUpWithError()
        layout = TieredGridLayout()
    }

    override func tearDownWithError() throws {
        layout = nil
        try super.tearDownWithError()
    }

    // MARK: - generatePositions Tests

    func testGeneratePositions_withZeroCount() {
        let positions = layout.generatePositions(numberOfItems: 0, width: 300)
        XCTAssertTrue(positions.isEmpty, "要素数が0の場合、positionsは空であることを確認")
    }

    func testGeneratePositions_withZeroWidth() {
        let positions = layout.generatePositions(numberOfItems: 5, width: 0)
        XCTAssertTrue(positions.isEmpty, "幅が0の場合、positionsは空であることを確認")
    }

    func testGeneratePositions_singleItem() {
        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(numberOfItems: 1, width: width)

        XCTAssertEqual(positions.count, 1)
        guard positions.count == 1 else { return }

        // アイテム 0: x=0, y=0, 幅=1, 高さ=1
        XCTAssertEqual(positions[0].0, CGPoint(x: 0 * unit, y: 0 * unit))
        XCTAssertEqual(positions[0].1, CGSize(width: 1 * unit, height: 1 * unit))
    }

    func testGeneratePositions_multipleItems_lessThanOneSet() {
        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(numberOfItems: 4, width: width)

        XCTAssertEqual(positions.count, 4)
        guard positions.count == 4 else { return }

        // アイテム 0
        XCTAssertEqual(positions[0].0, CGPoint(x: 0 * unit, y: 0 * unit))
        XCTAssertEqual(positions[0].1, CGSize(width: 1 * unit, height: 1 * unit))
        // アイテム 1
        XCTAssertEqual(positions[1].0, CGPoint(x: 1 * unit, y: 0 * unit))
        XCTAssertEqual(positions[1].1, CGSize(width: 1 * unit, height: 1 * unit))
        // アイテム 2
        XCTAssertEqual(positions[2].0, CGPoint(x: 2 * unit, y: 0 * unit))
        XCTAssertEqual(positions[2].1, CGSize(width: 1 * unit, height: 1 * unit))
        // アイテム 3
        XCTAssertEqual(positions[3].0, CGPoint(x: 0 * unit, y: 1 * unit))
        XCTAssertEqual(positions[3].1, CGSize(width: 2 * unit, height: 2 * unit))
    }

    func testGeneratePositions_oneFullSet() {
        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(numberOfItems: 10, width: width)

        XCTAssertEqual(positions.count, 10)
        guard positions.count == 10 else { return }

        // 最後のアイテムを確認 (アイテム 9)
        XCTAssertEqual(positions[9].0, CGPoint(x: 0 * unit, y: 4 * unit))
        XCTAssertEqual(positions[9].1, CGSize(width: 3 * unit, height: 3 * unit))
    }

    func testGeneratePositions_moreThanOneSet() {
        let width: CGFloat = 300
        let unit = width / 3
        let setHeight = setHeightInUnits * unit
        let positions = layout.generatePositions(numberOfItems: 11, width: width) // 1フルセット + 1アイテム

        XCTAssertEqual(positions.count, 11)
        guard positions.count == 11 else { return }

        // 2番目のセットの最初のアイテムを確認 (アイテム 10, パターンアイテム 0)
        XCTAssertEqual(positions[10].0, CGPoint(x: 0 * unit, y: 0 * unit + setHeight))
        XCTAssertEqual(positions[10].1, CGSize(width: 1 * unit, height: 1 * unit))

        // 2番目のセットの別のアイテムを確認 (アイテム 13, パターンアイテム 3)
        let positions13 = layout.generatePositions(numberOfItems: 14, width: width) // 1フルセット + 4アイテム
        XCTAssertEqual(positions13[13].0, CGPoint(x: 0 * unit, y: 1 * unit + setHeight))
        XCTAssertEqual(positions13[13].1, CGSize(width: 2 * unit, height: 2 * unit))
    }
}
