# TieredGridLayout

`TieredGridLayout` は、SwiftUIの`Layout`プロトコルを使用して実装されたカスタムレイアウトコンポーネント（フレームワーク）です。このレイアウトは、複数の要素を階層的なグリッドパターンで配置します。

`SampleApp` は `TieredGridLayout` フレームワークの使用方法を示すサンプルアプリケーションです。

## 特徴

- 単一サイズの小ブロック(1x1)、中ブロック(2x2)、大ブロック(3x3)を組み合わせたレイアウト
- SwiftUIのLayoutプロトコルによる実装
- ブロック数に応じた動的なレイアウト調整

## 実装の詳細

### Layoutプロトコル

TieredGridLayoutはSwiftUIの`Layout`プロトコルを実装しています。このプロトコルは以下の2つの必須メソッドを要求します：

1. **sizeThatFits** - レイアウトの全体サイズを計算します
2. **placeSubviews** - サブビューを配置します

### レイアウトパターン

レイアウトは10ブロックごとに以下のパターンを繰り返します

- **上段**: 横に3つの小ブロック(1x1)
- **中段**: 左に1つの中ブロック(2x2) + 右に縦に2つの小ブロック(1x1)
- **下段**: 横に3つの小ブロック(1x1)
- **最下段**: 1つの大ブロック(3x3)

## 使用方法

```swift
TieredGridLayout {
    // ここにサブビューを追加
    ForEach(items) { item in
        ...
    }
}
```

## プロジェクト構成

- `TieredGridLayout/`: カスタムレイアウトを提供するフレームワークのソースコード
- `SampleApp/`: `TieredGridLayout` を使用するサンプルアプリケーションのソースコード
- `TieredGridLayoutUITests/`: フレームワークのUIテスト
- `project.yml`: XcodeGen のプロジェクト定義ファイル

## 開発環境

```bash
brew install mint
mint bootstrap
mint run xcodegen # .xcodeproj を生成
```

これにより、プロジェクトで使用している以下のツールが自動的にインストールされます：
- SwiftLint (0.52.3)
- SwiftFormat (0.52.0)
- XcodeGen (2.40.1)

## サンプルアプリケーションの実行

1. 上記の「開発環境」セクションの手順に従って、必要なツールをインストールし、プロジェクトファイル (`.xcodeproj`) を生成します。
2. 生成された `TieredGridLayout.xcodeproj` ファイルを Xcode で開きます。
3. Xcode のスキームセレクタ（ツールバー中央付近）で `SampleApp` を選択します。
4. ビルドして実行（Cmd+R）します。