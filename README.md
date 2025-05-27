# TieredGridLayout

`TieredGridLayout` は、SwiftUIの`Layout`プロトコルを使用して実装されたカスタムレイアウトコンポーネントです

`SampleApp` は `TieredGridLayout` ライブラリの使用方法を示すサンプルアプリケーションです

## 特徴

- 単一サイズの小ブロック(1x1)、中ブロック(2x2)、大ブロック(3x3)を組み合わせたレイアウト
- ブロック数に応じた動的なレイアウト調整
- レイアウト計算結果をキャッシュし、再描画時のパフォーマンスを向上

## 必要条件

- iOS 16.0+
- macOS 13.0+

## 実装の詳細

### Layoutプロトコル

TieredGridLayoutはSwiftUIの`Layout`プロトコルを実装しています。このプロトコルは以下の2つの必須メソッドを要求します

1. **sizeThatFits** - レイアウトの全体サイズを計算します
2. **placeSubviews** - サブビューを配置します

### レイアウトパターン

レイアウトは10ブロックごとに以下のパターンを繰り返します

- **上段**: 横に3つの小ブロック(1x1)
- **中段**: 左に1つの中ブロック(2x2) + 右に縦に2つの小ブロック(1x1)
- **下段**: 横に3つの小ブロック(1x1)
- **最下段**: 1つの大ブロック(3x3)

## 使用方法

### Swift Package Manager

1. Xcode でプロジェクトを開き、「File」>「Add Packages...」を選択します
2. 検索バーにこのリポジトリの URL (`https://github.com/akitorahayashi/tiered-grid-layout` ) を貼り付けます
3. 「Dependency Rule」を選択し（通常は「Up to Next Major Version」）、バージョンを指定します。
4. 「Add Package」をクリックします。
5. ターゲットの「Frameworks, Libraries, and Embedded Content」セクションに `TieredGridLayout` が追加されていることを確認します。

```swift
import SwiftUI
import TieredGridLayout

// VStackやHStackのようにTieredGridLayoutを使用して子ビューを配置します
TieredGridLayout {
    // ここに子ビューを直接追加します
    Rectangle().fill(.blue)
    Rectangle().fill(.red)
    Rectangle().fill(.green)
    // さらにビューを追加...
}
```

### アスペクト比の扱い

`TieredGridLayout` は、利用可能な幅を3分割した単位に基づいて位置とサイズを計算し、サブビューには常に1:1 のアスペクト比のスペースを提案します。

SwiftUI の `Layout` プロトコルの設計上、レイアウトコンテナはスペースを提供する役割を担い、そのスペース内でコンテンツがどのように表示されるか（アスペクト比を保つか、引き伸ばすか、切り取るかなど）は、サブビュー自身とそのモディファイア（例: `.resizable()`, `.scaledToFit()`, `.scaledToFill().clipped()`）が決定します

したがって、1:1 ではないコンテンツ（写真など）を `TieredGridLayout` に配置する場合は、意図した表示になるように、各サブビューに適切なモディファイアを適用してください

```swift
TieredGridLayout {
    ForEach(myImageItems) { item in
        Image(item.name)
            .resizable()
            .scaledToFill()
            .clipped()
    }
}
```

## プロジェクト構成

- `TieredGridLayout/`: カスタムレイアウトを提供するライブラリのソースコード
- `SampleApp/`: `TieredGridLayout` を使用するサンプルアプリケーションのソースコード
- `project.yml`: XcodeGen で生成するプロジェクトを定義するファイル

## 開発環境

```bash
brew install mint
mint bootstrap
```

これにより、プロジェクトで使用している以下のツールが自動的にインストールされます：
- SwiftLint (0.52.3)
- SwiftFormat (0.52.0)
- XcodeGen (2.40.1)

xcodeproj を生成
```bash
mint run xcodegen
```
## サンプルアプリケーションの実行

1. 上記の「開発環境」セクションの手順に従って、必要なツールをインストールし、プロジェクトファイル (`.xcodeproj`) を生成します。
2. 生成された `TieredGridLayout.xcodeproj` ファイルを Xcode で開きます。
3. Xcode のスキームセレクタ（ツールバー中央付近）で `SampleApp` を選択します。
4. 実行（Cmd+R）します。

## カスタマイズ

### itemAlignmentInElement

初期化時に `itemAlignmentInElement` パラメータを使用して、レイアウト内の各要素におけるアイテムの配置位置を決定できます。このパラメータは、標準の SwiftUI `Alignment` 値（例：`.center`、`.topLeading`、`.bottomTrailing`）を受け入れます。

```swift
struct ContentView: View {
    var body: some View {
        TieredGridLayout(itemAlignmentInElement: .center) {
            ForEach(0..<10) { index in
                Color.blue
                    .overlay(Text("\(index)"))
            }
        }
    }
}
```

デフォルトの配置は `.center` です。このパラメータは各要素内でのアイテムの配置位置を制御します。

### layoutPattern

`layoutPattern` パラメータを使用して、レイアウトのパターンをカスタマイズできます。デフォルトでは以下のパターンが使用されます：

```swift
TGLayoutPattern(layers: [
    .threeSmall,                    // 上段：小アイテム3つ
    .mediumWithTwoSmall(mediumOnLeft: true), // 中段：中アイテム1つ + 小アイテム2つ
    .threeSmall,                    // 下段：小アイテム3つ
    .oneLarge                       // 最下段：大アイテム1つ
])
```

カスタムパターンを作成する例：

```swift
struct ContentView: View {
    var body: some View {
        let customPattern = TGLayoutPattern(layers: [
            .threeSmall,
            .mediumWithTwoSmall(mediumOnLeft: false), // 中アイテムを右側に配置
            .oneLarge
        ])
        
        TieredGridLayout(layoutPattern: customPattern) {
            ForEach(0..<10) { index in
                Color.blue
                    .overlay(Text("\(index)"))
            }
        }
    }
}
```

利用可能なレイヤータイプ：
- `.threeSmall`: 横に3つの小ブロック(1x1)を配置
- `.mediumWithTwoSmall(mediumOnLeft: Bool)`: 中ブロック(2x2)と小ブロック(1x1)2つを配置（中ブロックの位置を指定可能）
- `.oneLarge`: 大ブロック(3x3)1つを配置

## テスト

### ユニットテスト

`TieredGridLayout` パッケージのユニットテストは、Swift Package Manager を使用して実行されます。
リポジトリのルートディレクトリで以下のコマンドを実行してください。

```bash
$ swift test
```

これにより、`TieredGridLayoutTests` ターゲット内のテストが実行されます。

### UIテスト

`SampleApp` のUIテストは、Xcodeのテストフレームワークを使用して実行されます。
テストを実行するには、まず `project.yml` からXcodeプロジェクトを生成する必要があります。

```bash
$ mint run xcodegen
```

その後、Xcode IDEからテストを実行できます。

これにより、`TieredGridLayoutUITests` ターゲット内のUIテストが実行され、`SampleApp` を使用してユーザーインターフェースとインタラクションを検証することができます。
