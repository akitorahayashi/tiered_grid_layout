import SwiftUI

public struct TieredGridLayout: Layout {
    private let alignment: Alignment
    public init(alignment: Alignment = .topLeading) { self.alignment = alignment }
    
    
    // MARK: - Layout sizing
    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let width = proposal.width ?? 0
        guard width > 0 else { return .zero }

        let unit = width / 3
        let completeSets = subviews.count / 10
        var height = CGFloat(completeSets) * (unit * 7)

        switch subviews.count % 10 {
        case 1...3:  height += unit           // 1行分
        case 4...6:  height += unit * 3       // 3行分
        case 7...9:  height += unit * 4       // 4行分
        case 0:      break                    // ちょうど 10 の倍数
        default:     height += unit * 7       // 理論上到達しない
        }

        return CGSize(width: width,
                      height: max(height, proposal.height ?? 0))
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        guard !subviews.isEmpty else { return }

        let positions = generatePositions(count: subviews.count, width: bounds.width)
        let anchor    = unitPoint(for: alignment)

        for (index, subview) in subviews.enumerated() where index < positions.count {
            let (pt, size) = positions[index]

            // anchor が .center なら (w/2, h/2) だけ右下へオフセット
            let offset = CGPoint(x: size.width  * anchor.x,
                                 y: size.height * anchor.y)

            subview.place(
                at: CGPoint(x: bounds.minX + pt.x + offset.x,
                            y: bounds.minY + pt.y + offset.y),
                anchor: anchor,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
        }
    }

    // Alignment → UnitPoint 変換
    private func unitPoint(for alignment: Alignment) -> UnitPoint {
        switch alignment {
        case .topLeading:     return .topLeading
        case .top:            return .top
        case .topTrailing:    return .topTrailing
        case .leading:        return .leading
        case .center:         return .center
        case .trailing:       return .trailing
        case .bottomLeading:  return .bottomLeading
        case .bottom:         return .bottom
        case .bottomTrailing: return .bottomTrailing
        default:              return .topLeading
        }
    }


    private func generatePositions(count: Int, width: CGFloat)
        -> [(CGPoint, CGSize)]
    {
        var positions: [(CGPoint, CGSize)] = []
        let unit = width / 3

        let small  = CGSize(width: unit,       height: unit)
        let medium = CGSize(width: unit * 2,   height: unit * 2)
        let large  = CGSize(width: unit * 3,   height: unit * 3)

        var idx = 0
        while idx < count {
            let setY = CGFloat(idx / 10) * unit * 7   // ← セット単位で固定

            // ① 上段（最大 3）
            for col in 0..<min(3, count - idx) {
                positions.append((CGPoint(x: unit * CGFloat(col), y: setY), small))
                idx += 1
            }
            if idx >= count { break }

            // ② 中段左（2×2）
            positions.append((CGPoint(x: 0, y: unit + setY), medium))
            idx += 1
            if idx >= count { break }

            // ③ 中段右（縦2）
            for row in 0..<min(2, count - idx) {
                positions.append((CGPoint(x: unit * 2,
                                           y: unit * (1 + CGFloat(row)) + setY), small))
                idx += 1
            }
            if idx >= count { break }

            // ④ 下段（最大 3）
            for col in 0..<min(3, count - idx) {
                positions.append((CGPoint(x: unit * CGFloat(col),
                                           y: unit * 3 + setY), small))
                idx += 1
            }
            if idx >= count { break }

            // ⑤ 最下段（3×3）
            positions.append((CGPoint(x: 0, y: unit * 4 + setY), large))
            idx += 1
        }
        return positions
    }
}
