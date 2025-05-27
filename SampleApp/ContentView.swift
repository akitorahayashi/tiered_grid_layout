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

    // カスタムレイアウトパターン
    private let customLayoutPattern = TGLayoutPattern(layers: [
        .threeSmall,
        .mediumWithTwoSmall(mediumOnLeft: true),
        .threeSmall,
        .mediumWithTwoSmall(mediumOnLeft: false),
        .threeSmall,
        .oneLarge,
        .threeSmall,
        .mediumWithTwoSmall(mediumOnLeft: false),
        .threeSmall,
        .mediumWithTwoSmall(mediumOnLeft: true),
        .threeSmall,
        .oneLarge,
    ])

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("デフォルトレイアウト")
                    .font(.headline)

                TieredGridLayout {
                    ForEach(sampleBlockModels) { block in
                        Rectangle()
                            .fill(block.color)
                            .border(Color.white, width: 2)
                    }
                }

                Text("カスタムレイアウト")
                    .font(.headline)
                    .padding(.top)

                TieredGridLayout(layoutPattern: customLayoutPattern) {
                    ForEach(sampleBlockModels) { block in
                        Rectangle()
                            .fill(block.color)
                            .border(Color.white, width: 2)
                    }
                }
            }
            .padding(.top, 50)
        }
    }
}

#Preview {
    ContentView()
}
