import SwiftUI

public struct TieredGridLayout: Layout {
    public init() {}

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        // proposal.width が nil の場合のデフォルト値を 300 から 0 に変更
        let width = proposal.width ?? 0
        guard width > 0 else { return .zero } // 幅が 0 以下ならサイズ 0 を返す

        let unitSize = width / 3

        // 完全な10ブロックのセット数を計算
        let completeSets = subviews.count / 10

        // 完全なセットの高さを計算
        var totalHeight = CGFloat(completeSets) * (unitSize * 7)

        // 最後の不完全なセットの残りのブロックの高さを計算
        let remainingBlocks = subviews.count % 10
        if remainingBlocks > 0 {
            switch remainingBlocks {
                case 1 ... 3:
                    // 上段のみが埋まっている場合
                    totalHeight += unitSize
                case 4 ... 6:
                    // 上段と中段の一部が埋まっている場合
                    totalHeight += unitSize * 3
                case 7 ... 9:
                    // 上段、中段、下段が埋まっている場合
                    totalHeight += unitSize * 4
                case 10:
                    // 完全なセット (remainingBlocks が 0 の場合はこの if に入らないため、ここは 10 のみ)
                    totalHeight += unitSize * 7
                default:
                    // ここには到達しない想定 (remainingBlocks は 1-10 の範囲)
                    break
            }
        }

        // 計算された高さと提案された高さの大きい方を返す
        let resultSize = CGSize(width: width, height: max(totalHeight, proposal.height ?? 0))
        return resultSize
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        guard !subviews.isEmpty else { return }

        let positions = generatePositions(count: subviews.count, width: bounds.width)

        for (index, subview) in subviews.enumerated() where index < positions.count {
            let (point, size) = positions[index]
            let adjustedPoint = CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y)
            subview.place(
                at: adjustedPoint,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
        }
    }

    private func generatePositions(count: Int, width: CGFloat) -> [(CGPoint, CGSize)] {
        var positions: [(CGPoint, CGSize)] = []

        let unitSize = width / 3

        // サイズを計算
        let smallSize = CGSize(width: unitSize, height: unitSize)
        let mediumSize = CGSize(width: unitSize * 2, height: unitSize * 2)
        let largeSize = CGSize(width: unitSize * 3, height: unitSize * 3)

        // 10ブロックのグループ単位で処理
        let blockCount = count
        var currentIndex = 0

        while currentIndex < blockCount {
            let setBaseY = (currentIndex / 10) * Int(unitSize * 7) // 1セットあたり7ユニットの高さ
            let remainingBlocks = min(10, blockCount - currentIndex)
            let setOffset = CGFloat(setBaseY)

            // 上段 - 3つの小ブロック
            // 最大3つの小ブロックを配置
            for index in 0 ..< min(3, blockCount - currentIndex) {
                positions.append((CGPoint(x: unitSize * CGFloat(index), y: setOffset), smallSize))
                currentIndex += 1
            }

            if currentIndex >= blockCount { break }

            // 中段 - 左に1つの中ブロック(2x2)
            positions.append((CGPoint(x: 0, y: unitSize + setOffset), mediumSize))
            currentIndex += 1

            // 中段 - 右に縦に2つの小ブロック
            // 最大2つの小ブロックを配置
            for index in 0 ..< min(2, blockCount - currentIndex) {
                positions.append((CGPoint(x: unitSize * 2, y: unitSize * (1 + CGFloat(index)) + setOffset), smallSize))
                currentIndex += 1
            }

            if currentIndex >= blockCount { break }

            // 下段 - 3つの小ブロック
            // 最大3つの小ブロックを配置
            for index in 0 ..< min(3, blockCount - currentIndex) {
                positions.append((CGPoint(x: unitSize * CGFloat(index), y: unitSize * 3 + setOffset), smallSize))
                currentIndex += 1
            }

            if currentIndex >= blockCount { break }

            // 最下段 - 1つの大ブロック(3x3)
            positions.append((CGPoint(x: 0, y: unitSize * 4 + setOffset), largeSize))
            currentIndex += 1

            // 10個のフルセットに満たない場合は継続する必要なし
            if remainingBlocks < 10 {
                break
            }
        }

        return positions
    }
}
