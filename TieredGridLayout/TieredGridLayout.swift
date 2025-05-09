import SwiftUI

public struct TieredGridLayout: Layout {
    private let alignment: Alignment
    public init(alignment: Alignment = .center) { self.alignment = alignment }

    // MARK: - Layout Pattern Definition

    private struct RelativeLayoutItem {
        let x: CGFloat // x offset in unit multiples
        let y: CGFloat // y offset in unit multiples
        let width: CGFloat // width in unit multiples
        let height: CGFloat // height in unit multiples
    }

    private static let layoutPattern: [RelativeLayoutItem] = [
        // ① 上段 (3 small items)
        RelativeLayoutItem(x: 0, y: 0, width: 1, height: 1), // Item 0
        RelativeLayoutItem(x: 1, y: 0, width: 1, height: 1), // Item 1
        RelativeLayoutItem(x: 2, y: 0, width: 1, height: 1), // Item 2
        // ② 中段左 (1 medium item)
        RelativeLayoutItem(x: 0, y: 1, width: 2, height: 2), // Item 3
        // ③ 中段右 (2 small items)
        RelativeLayoutItem(x: 2, y: 1, width: 1, height: 1), // Item 4
        RelativeLayoutItem(x: 2, y: 2, width: 1, height: 1), // Item 5
        // ④ 下段 (3 small items)
        RelativeLayoutItem(x: 0, y: 3, width: 1, height: 1), // Item 6
        RelativeLayoutItem(x: 1, y: 3, width: 1, height: 1), // Item 7
        RelativeLayoutItem(x: 2, y: 3, width: 1, height: 1), // Item 8
        // ⑤ 最下段 (1 large item)
        RelativeLayoutItem(x: 0, y: 4, width: 3, height: 3), // Item 9
    ]

    private static let setHeightInUnits: CGFloat = 7 // Pattern height in units

    // MARK: - Layout sizing

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let width: CGFloat = proposal.width ?? 0
        guard width > 0 else { return .zero }

        let unit: CGFloat = width / 3
        let count: Int = subviews.count
        let completeSets: Int = count / 10
        let remainingItems: Int = count % 10
        var height = CGFloat(completeSets) * unit * Self.setHeightInUnits

        // Calculate height for remaining items
        if remainingItems > 0 {
            // Find the maximum y + height of the remaining items in the pattern
            let maxRelativeYPlusHeight = Self.layoutPattern[..<remainingItems]
                .map { $0.y + $0.height }
                .max() ?? 0
            height += maxRelativeYPlusHeight * unit
        }

        let proposedHeight: CGFloat = proposal.height ?? 0
        return CGSize(
            width: width,
            height: max(height, proposedHeight)
        )
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        guard !subviews.isEmpty else { return }

        let width: CGFloat = bounds.width
        let positions: [(CGPoint, CGSize)] = generatePositions(count: subviews.count, width: width)
        let anchor: UnitPoint = unitPoint(for: alignment)

        for (index, subview) in subviews.enumerated() where index < positions.count {
            let (pt, size): (CGPoint, CGSize) = positions[index]

            // anchor が .center なら (w/2, h/2) だけ右下へオフセット
            let offsetX: CGFloat = size.width * anchor.x
            let offsetY: CGFloat = size.height * anchor.y
            let offset = CGPoint(x: offsetX, y: offsetY)

            let placeX: CGFloat = bounds.minX + pt.x + offset.x
            let placeY: CGFloat = bounds.minY + pt.y + offset.y

            subview.place(
                at: CGPoint(x: placeX, y: placeY),
                anchor: anchor,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
        }
    }

    // Alignment → UnitPoint 変換
    func unitPoint(for alignment: Alignment) -> UnitPoint {
        switch alignment {
            case .topLeading: return .topLeading
            case .top: return .top
            case .topTrailing: return .topTrailing
            case .leading: return .leading
            case .center: return .center
            case .trailing: return .trailing
            case .bottomLeading: return .bottomLeading
            case .bottom: return .bottom
            case .bottomTrailing: return .bottomTrailing
            default: return .topLeading // デフォルトは .topLeading に
        }
    }

    func generatePositions(count: Int, width: CGFloat)
        -> [(CGPoint, CGSize)]
    {
        var positions: [(CGPoint, CGSize)] = []
        // swiftlint:disable:next empty_count
        guard count > 0, width > 0 else { return positions }

        let unit: CGFloat = width / 3
        positions.reserveCapacity(count)

        for index in 0 ..< count {
            let setIndex: Int = index / 10
            let patternIndex: Int = index % 10

            let patternItem = Self.layoutPattern[patternIndex]

            let setY = CGFloat(setIndex) * unit * Self.setHeightInUnits

            let xPos: CGFloat = patternItem.x * unit
            let yPos: CGFloat = patternItem.y * unit + setY
            let itemWidth: CGFloat = patternItem.width * unit
            let itemHeight: CGFloat = patternItem.height * unit

            let point = CGPoint(x: xPos, y: yPos)
            let size = CGSize(width: itemWidth, height: itemHeight)

            positions.append((point, size))
        }

        return positions
    }
}
