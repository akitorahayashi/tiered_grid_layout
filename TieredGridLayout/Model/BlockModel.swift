import SwiftUI

public struct BlockModel: Identifiable {
    public var id = UUID()
    public let color: Color

    public init(id: UUID = UUID(), color: Color) {
        self.id = id
        self.color = color
    }
}
