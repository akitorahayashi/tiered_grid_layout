import SwiftUI
import TieredGridLayout

struct TestContentView: View {
    @State private var itemCount: Int = 5

    var body: some View {
        VStack {
            // アイテム数を変更するコントロール
            HStack {
                Button("Decrease") {
                    if itemCount > 0 {
                        itemCount -= 1
                    }
                }
                .accessibilityIdentifier(AccessibilityID.decreaseButton.rawValue)
                Spacer()
                Text("Items: \(itemCount)")
                Spacer()
                Button("Increase") {
                    itemCount += 1
                }
                .accessibilityIdentifier(AccessibilityID.increaseButton.rawValue)
            }
            .padding()

            // ScrollView containing the TieredGridLayout
            ScrollView {
                TieredGridLayout(alignment: .topLeading) {
                    ForEach(0 ..< itemCount, id: \.self) { index in
                        let color = TestingConstants.defaultColors[index % TestingConstants.defaultColors.count]
                        Rectangle()
                            .fill(color)
                            .overlay(
                                Text("\(index)")
                                    .foregroundColor(.white)
                            )
                            .accessibilityIdentifier(AccessibilityID.item(index: index))
                    }
                }
            }
            .accessibilityIdentifier(AccessibilityID.gridContainer.rawValue)
            // テストのため ScrollView にフレームを設定
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
