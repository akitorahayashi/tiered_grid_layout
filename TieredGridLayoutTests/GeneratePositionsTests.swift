import SwiftUI
@testable import TieredGridLayout
import XCTest

final class GeneratePositionsTests: XCTestCase {
    private let setHeightInUnits: CGFloat = 7
    private let defaultPattern = TGLayoutPattern(layers: [
        .threeSmall,
        .mediumWithTwoSmall(mediumOnLeft: true),
        .threeSmall,
        .oneLarge,
    ])

    var layout: TieredGridLayout!

    override func setUpWithError() throws {
        try super.setUpWithError()
        layout = TieredGridLayout(layoutPattern: defaultPattern)
    }

    override func tearDownWithError() throws {
        layout = nil
        try super.tearDownWithError()
    }

    // MARK: - Layer Type Tests

    func testThreeSmallLayerPositions() {
        let pattern = TGLayoutPattern(layers: [.threeSmall])
        layout = TieredGridLayout(layoutPattern: pattern)

        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(numberOfItems: 3, width: width)

        XCTAssertEqual(positions.count, 3)
        guard positions.count == 3 else { return }

        // 3つの小アイテムが横に並ぶことを確認
        for i in 0 ..< 3 {
            XCTAssertEqual(positions[i].0, CGPoint(x: CGFloat(i) * unit, y: 0 * unit))
            XCTAssertEqual(positions[i].1, CGSize(width: 1 * unit, height: 1 * unit))
        }
    }

    func testMediumWithTwoSmallLayerPositions_MediumOnLeft() {
        let pattern = TGLayoutPattern(layers: [.mediumWithTwoSmall(mediumOnLeft: true)])
        layout = TieredGridLayout(layoutPattern: pattern)

        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(numberOfItems: 3, width: width)

        XCTAssertEqual(positions.count, 3)
        guard positions.count == 3 else { return }

        // 中アイテムが左に配置
        XCTAssertEqual(positions[0].0, CGPoint(x: 0 * unit, y: 0 * unit))
        XCTAssertEqual(positions[0].1, CGSize(width: 2 * unit, height: 2 * unit))

        // 小アイテム2つが右に縦に並ぶ
        XCTAssertEqual(positions[1].0, CGPoint(x: 2 * unit, y: 0 * unit))
        XCTAssertEqual(positions[1].1, CGSize(width: 1 * unit, height: 1 * unit))
        XCTAssertEqual(positions[2].0, CGPoint(x: 2 * unit, y: 1 * unit))
        XCTAssertEqual(positions[2].1, CGSize(width: 1 * unit, height: 1 * unit))
    }

    func testMediumWithTwoSmallLayerPositions_MediumOnRight() {
        let pattern = TGLayoutPattern(layers: [.mediumWithTwoSmall(mediumOnLeft: false)])
        layout = TieredGridLayout(layoutPattern: pattern)

        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(numberOfItems: 3, width: width)

        XCTAssertEqual(positions.count, 3)
        guard positions.count == 3 else { return }

        // 小アイテム2つが左に縦に並ぶ
        XCTAssertEqual(positions[0].0, CGPoint(x: 0 * unit, y: 0 * unit))
        XCTAssertEqual(positions[0].1, CGSize(width: 1 * unit, height: 1 * unit))
        XCTAssertEqual(positions[1].0, CGPoint(x: 0 * unit, y: 1 * unit))
        XCTAssertEqual(positions[1].1, CGSize(width: 1 * unit, height: 1 * unit))

        // 中アイテムが右に配置
        XCTAssertEqual(positions[2].0, CGPoint(x: 1 * unit, y: 0 * unit))
        XCTAssertEqual(positions[2].1, CGSize(width: 2 * unit, height: 2 * unit))
    }

    func testOneLargeLayerPositions() {
        let pattern = TGLayoutPattern(layers: [.oneLarge])
        layout = TieredGridLayout(layoutPattern: pattern)

        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(numberOfItems: 1, width: width)

        XCTAssertEqual(positions.count, 1)
        guard positions.count == 1 else { return }

        // 大アイテムが配置
        XCTAssertEqual(positions[0].0, CGPoint(x: 0 * unit, y: 0 * unit))
        XCTAssertEqual(positions[0].1, CGSize(width: 3 * unit, height: 3 * unit))
    }

    // MARK: - Multiple Layer Tests

    func testMultipleLayersWithDefaultPattern() {
        let width: CGFloat = 300
        let unit = width / 3
        let positions = layout.generatePositions(numberOfItems: 10, width: width)

        XCTAssertEqual(positions.count, 10)
        guard positions.count == 10 else { return }

        // 最初の層: 3つの小アイテム
        for i in 0 ..< 3 {
            XCTAssertEqual(positions[i].0, CGPoint(x: CGFloat(i) * unit, y: 0 * unit))
            XCTAssertEqual(positions[i].1, CGSize(width: 1 * unit, height: 1 * unit))
        }

        // 2番目の層: 中アイテム + 2つの小アイテム
        XCTAssertEqual(positions[3].0, CGPoint(x: 0 * unit, y: 1 * unit))
        XCTAssertEqual(positions[3].1, CGSize(width: 2 * unit, height: 2 * unit))
        XCTAssertEqual(positions[4].0, CGPoint(x: 2 * unit, y: 1 * unit))
        XCTAssertEqual(positions[4].1, CGSize(width: 1 * unit, height: 1 * unit))
        XCTAssertEqual(positions[5].0, CGPoint(x: 2 * unit, y: 2 * unit))
        XCTAssertEqual(positions[5].1, CGSize(width: 1 * unit, height: 1 * unit))

        // 3番目の層: 3つの小アイテム
        for i in 6 ..< 9 {
            XCTAssertEqual(positions[i].0, CGPoint(x: CGFloat(i - 6) * unit, y: 3 * unit))
            XCTAssertEqual(positions[i].1, CGSize(width: 1 * unit, height: 1 * unit))
        }

        // 4番目の層: 大アイテム
        XCTAssertEqual(positions[9].0, CGPoint(x: 0 * unit, y: 4 * unit))
        XCTAssertEqual(positions[9].1, CGSize(width: 3 * unit, height: 3 * unit))
    }

    // MARK: - Edge Case Tests

    func testEmptyPositionsWhenItemCountIsZero() {
        let positions = layout.generatePositions(numberOfItems: 0, width: 300)
        XCTAssertTrue(positions.isEmpty, "要素数が0の場合、positionsは空であることを確認")
    }

    func testEmptyPositionsWhenWidthIsZero() {
        let positions = layout.generatePositions(numberOfItems: 5, width: 0)
        XCTAssertTrue(positions.isEmpty, "幅が0の場合、positionsは空であることを確認")
    }
}
