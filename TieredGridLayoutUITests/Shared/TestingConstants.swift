import Foundation
import SwiftUI

enum AccessibilityID: String {
    // 静的な要素のID
    case decreaseButton
    case increaseButton
    case gridContainer

    // グリッド内の動的に生成されるアイテム用
    static func item(index: Int) -> String {
        "item_\(index)"
    }
}

enum LaunchArgument: String {
    case uiTesting
}

enum TestingConstants {
    static let defaultColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown,
    ]
}
