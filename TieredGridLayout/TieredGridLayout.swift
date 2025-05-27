import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct TieredGridLayout: Layout {
    public struct CacheData {
        var cachedWidth: CGFloat?
        var cachedCount: Int?
        var positions: [(CGPoint, CGSize)]?
        var calculatedHeight: CGFloat?
    }

    public typealias Cache = CacheData

    // Layoutプロトコルのメソッド、レイアウト処理を開始する際に、レイアウトインスタンスごとに最初に呼び出される
    @available(iOS 16.0, macOS 13.0, *)
    public func makeCache(subviews _: Subviews) -> CacheData {
        CacheData()
    }

    let itemAlignmentInElement: Alignment
    let pattern: TGLayoutPattern

    @available(iOS 16.0, macOS 13.0, *)
    public init(alignment: Alignment = .center, pattern: TGLayoutPattern = .default) {
        self.itemAlignmentInElement = alignment
        self.pattern = pattern
    }

    // MARK: - レイアウトパターン

    private struct RelativeLayoutItem {
        let x: CGFloat // ユニット単位のxオフセット
        let y: CGFloat // ユニット単位のyオフセット
        let width: CGFloat // ユニット単位の幅
        let height: CGFloat // ユニット単位の高さ
    }

    private func generateLayoutPattern() -> [RelativeLayoutItem] {
        var items: [RelativeLayoutItem] = []
        var currentY: CGFloat = 0

        for layer in pattern.layers {
            switch layer.type {
            case .threeSmall:
                // 小アイテム3つを横に並べる
                for i in 0..<3 {
                    items.append(RelativeLayoutItem(x: CGFloat(i), y: currentY, width: 1, height: 1))
                }
            case .mediumWithTwoSmall(let mediumOnLeft):
                if mediumOnLeft {
                    // 中アイテム1つを左に配置
                    items.append(RelativeLayoutItem(x: 0, y: currentY, width: 2, height: 2))
                    // 小アイテム2つを右に縦に並べる
                    for i in 0..<2 {
                        items.append(RelativeLayoutItem(x: 2, y: currentY + CGFloat(i), width: 1, height: 1))
                    }
                } else {
                    // 小アイテム2つを左に縦に並べる
                    for i in 0..<2 {
                        items.append(RelativeLayoutItem(x: 0, y: currentY + CGFloat(i), width: 1, height: 1))
                    }
                    // 中アイテム1つを右に配置
                    items.append(RelativeLayoutItem(x: 1, y: currentY, width: 2, height: 2))
                }
            case .oneLarge:
                // 大アイテム1つを配置
                items.append(RelativeLayoutItem(x: 0, y: currentY, width: 3, height: 3))
            }
            currentY += layer.unitHeight
        }

        return items
    }

    private var layoutPattern: [RelativeLayoutItem] {
        generateLayoutPattern()
    }

    private var setHeightInUnits: CGFloat {
        pattern.layers.reduce(0) { $0 + $1.unitHeight }
    }

    // コンテナの全高を計算
    @available(iOS 16.0, macOS 13.0, *)
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let width: CGFloat = proposal.width ?? 0
        guard width > 0 else { return .zero }
        let count: Int = subviews.count

        // 高さ計算のためのキャッシュ有効性を確認
        if let cachedW = cache.cachedWidth, let cachedC = cache.cachedCount, let cachedH = cache.calculatedHeight,
           cachedW == width, cachedC == count
        {
            return CGSize(width: width, height: max(cachedH, proposal.height ?? 0))
        }

        let unit: CGFloat = width / 3
        let setSize = layoutPattern.count
        let completeSets: Int = count / setSize
        let remainingItems: Int = count % setSize
        var height = CGFloat(completeSets) * unit * setHeightInUnits

        if remainingItems > 0 {
            let maxRelativeYPlusHeight = layoutPattern[..<remainingItems]
                .map { $0.y + $0.height }
                .max() ?? 0
            height += maxRelativeYPlusHeight * unit
        }

        // 新しく計算された高さとパラメータでキャッシュを更新
        cache.cachedWidth = width
        cache.cachedCount = count
        cache.calculatedHeight = height
        cache.positions = nil // 高さが変更された場合、位置を無効化

        let proposedHeight: CGFloat = proposal.height ?? 0
        return CGSize(
            width: width,
            height: max(height, proposedHeight)
        )
    }

    @available(iOS 16.0, macOS 13.0, *)
    public func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) {
        guard !subviews.isEmpty else { return }

        let currentWidth: CGFloat = bounds.width
        let currentCount: Int = subviews.count
        var positionsToUse: [(CGPoint, CGSize)]

        // 位置情報のキャッシュ有効性を確認
        if let cachedW = cache.cachedWidth, let cachedC = cache.cachedCount, let cachedPositions = cache.positions,
           cachedW == currentWidth, cachedC == currentCount
        {
            positionsToUse = cachedPositions
        } else {
            // キャッシュ無効/未計算時: 位置を生成
            positionsToUse = generatePositions(numberOfItems: currentCount, width: currentWidth)
            // 新しい位置とパラメータでキャッシュを更新
            cache.cachedWidth = currentWidth
            cache.cachedCount = currentCount
            cache.positions = positionsToUse
            // cache.calculatedHeight は、この幅で sizeThatFits が呼び出されていない場合、古い可能性があります。
            // SwiftUIのレイアウト処理では通常 sizeThatFits が先に呼び出されるため、
            // ここでは高さの再計算は行いません。
        }

        let anchor: UnitPoint = unitPoint(for: itemAlignmentInElement)

        for (index, subview) in subviews.enumerated() where index < positionsToUse.count {
            let (pt, size): (CGPoint, CGSize) = positionsToUse[index]

            // anchor が .center なら (w/2, h/2) だけ右下へ移動
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

    // Alignment から UnitPoint への変換
    @available(iOS 16.0, macOS 13.0, *)
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
            default: return .center // デフォルトは .center
        }
    }

    @available(iOS 16.0, macOS 13.0, *)
    func generatePositions(numberOfItems: Int, width: CGFloat)
        -> [(CGPoint, CGSize)]
    {
        var positions: [(CGPoint, CGSize)] = []
        guard numberOfItems > 0, width > 0 else { return positions }

        let unit: CGFloat = width / 3
        let pattern = layoutPattern
        let setSize = pattern.count
        positions.reserveCapacity(numberOfItems)

        for index in 0 ..< numberOfItems {
            let setIndex: Int = index / setSize
            let patternIndex: Int = index % setSize

            let patternItem = pattern[patternIndex]
            let setY = CGFloat(setIndex) * unit * setHeightInUnits

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
