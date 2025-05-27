import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
public struct TGLayoutPattern {
    public enum LayerType {
        case threeSmall // 小アイテム3つ
        case mediumWithTwoSmall(mediumOnLeft: Bool) // 中アイテム1つ + 小アイテム2つ（中アイテムの位置を指定）
        case oneLarge // 大アイテム1つ
    }

    public struct Layer {
        public let type: LayerType
        public let unitHeight: CGFloat // この層の高さ（ユニット数）

        public init(type: LayerType, unitHeight: CGFloat) {
            self.type = type
            self.unitHeight = unitHeight
        }
    }

    public let layers: [Layer]

    public init(layers: [Layer]) {
        self.layers = layers
    }

    // デフォルトのレイアウトパターン
    public static let `default`: TGLayoutPattern = {
        let layers: [Layer] = [
            Layer(type: .threeSmall, unitHeight: 1),
            Layer(type: .mediumWithTwoSmall(mediumOnLeft: true), unitHeight: 2),
            Layer(type: .threeSmall, unitHeight: 1),
            Layer(type: .oneLarge, unitHeight: 3)
        ]
        return TGLayoutPattern(layers: layers)
    }()
} 