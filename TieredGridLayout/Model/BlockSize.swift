import SwiftUI

enum BlockSize {
    case small // 小さな正方形 (1x1)
    case medium // 中サイズの正方形 (2x2)
    case large // 大きな正方形 (3x3)

    // グリッド単位でのサイズを取得 (整数値)
    var gridUnits: (width: Int, height: Int) {
        switch self {
            case .small:
                return (1, 1)
            case .medium:
                return (2, 2)
            case .large:
                return (3, 3)
        }
    }

    // ブロックの相対的なサイズを取得
    func size(unitSize: CGFloat) -> CGSize {
        let (width, height) = gridUnits
        return CGSize(width: unitSize * CGFloat(width), height: unitSize * CGFloat(height))
    }
}
