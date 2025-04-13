import SwiftUI
import TieredGridLayout

struct BlockModel: Identifiable {
    var id = UUID()
    let color: Color

    init(id: UUID = UUID(), color: Color) {
        self.id = id
        self.color = color
    }
}

struct ContentView: View {
    // サンプル
    let sampleBlockModels: [BlockModel] = [
        BlockModel(color: .red),
        BlockModel(color: .orange),
        BlockModel(color: .yellow),
        BlockModel(color: .green),
        BlockModel(color: .blue),
        BlockModel(color: .purple),
        BlockModel(color: .pink),
        BlockModel(color: .brown),
        BlockModel(color: .gray),
        BlockModel(color: .cyan),
        BlockModel(color: .indigo),
        BlockModel(color: .mint),
        BlockModel(color: .cyan),
        BlockModel(color: .teal),
    ]

    var body: some View {
        ScrollView {
            TieredGridLayout {
                ForEach(Array(sampleBlockModels.enumerated()), id: \.element.id) { _, block in
                    Rectangle()
                        .fill(block.color)
                        .border(Color.white, width: 2)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
