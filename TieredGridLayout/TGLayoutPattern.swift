import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public enum TGLayer {
    case threeSmall // 小アイテム3つ
    case mediumWithTwoSmall(mediumOnLeft: Bool) // 中アイテム1つ + 小アイテム2つ（中アイテムの位置を指定）
    case oneLarge // 大アイテム1つ
    
    public var unitHeight: CGFloat {
        switch self {
        case .threeSmall:
            return 1
        case .mediumWithTwoSmall:
            return 2
        case .oneLarge:
            return 3
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
public struct TGLayoutPattern {
    public let layers: [TGLayer]

    public init(layers: [TGLayer] = [
        .threeSmall,
        .mediumWithTwoSmall(mediumOnLeft: true),
        .threeSmall,
        .oneLarge
    ]) {
        self.layers = layers
    }
} 