//
//  MiteneLayout.swift
//  TieredGridLayout
//
//  Created by akitorahayashi on 2025/04/12.
//

import SwiftUI

struct TieredGridLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        let width = proposal.width ?? 300
        let unitSize = width / 3
        
        // 実際のレイアウトに基づいて高さを計算
        let blockCount = subviews.count
        
        // 完全な10ブロックのセット数を計算
        let completeSets = blockCount / 10
        
        // 完全なセットの高さを計算
        var totalHeight = CGFloat(completeSets) * (unitSize * 7)
        
        // 最後の不完全なセットの残りのブロックの高さを計算
        let remainingBlocks = blockCount % 10
        if remainingBlocks > 0 {
            // 最後のブロックの位置に基づいて高さを決定
            if remainingBlocks <= 3 {
                // 上段のみが埋まっている場合
                totalHeight += unitSize
            } else if remainingBlocks <= 6 {
                // 上段と中段の一部が埋まっている場合
                totalHeight += unitSize * 3
            } else if remainingBlocks <= 9 {
                // 上段、中段、下段が埋まっている場合
                totalHeight += unitSize * 4
            } else { // remainingBlocks == 10
                // 完全なセット
                totalHeight += unitSize * 7
            }
        }
        
        return CGSize(width: width, height: totalHeight)
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard !subviews.isEmpty else { return }
        
        let positions = generatePositions(count: subviews.count, width: bounds.width)
        
        for (index, subview) in subviews.enumerated() where index < positions.count {
            let (point, size) = positions[index]
            let adjustedPoint = CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y)
            subview.place(
                at: adjustedPoint,
                anchor: .topLeading,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
        }
    }
    
    private func generatePositions(count: Int, width: CGFloat) -> [(CGPoint, CGSize)] {
        var positions: [(CGPoint, CGSize)] = []
        
        let unitSize = width / 3
        
        // サイズを計算
        let smallSize = CGSize(width: unitSize, height: unitSize)
        let mediumSize = CGSize(width: unitSize * 2, height: unitSize * 2)
        let largeSize = CGSize(width: unitSize * 3, height: unitSize * 3)
        
        // 10ブロックのグループ単位で処理
        let blockCount = count
        var currentIndex = 0
        
        while currentIndex < blockCount {
            let setBaseY = (currentIndex / 10) * Int(unitSize * 7) // 1セットあたり7ユニットの高さ
            let remainingBlocks = min(10, blockCount - currentIndex)
            let setOffset = CGFloat(setBaseY)
            
            // 上段 - 3つの小ブロック
            // 最大3つの小ブロックを配置
            for index in 0..<min(3, blockCount - currentIndex) {
                positions.append((CGPoint(x: unitSize * CGFloat(index), y: setOffset), smallSize))
                currentIndex += 1
            }
            
            if currentIndex >= blockCount { break }
            
            // 中段 - 左に1つの中ブロック(2x2)
            positions.append((CGPoint(x: 0, y: unitSize + setOffset), mediumSize))
            currentIndex += 1
            
            // 中段 - 右に縦に2つの小ブロック
            // 最大2つの小ブロックを配置
            for index in 0..<min(2, blockCount - currentIndex) {
                positions.append((CGPoint(x: unitSize * 2, y: unitSize * (1 + CGFloat(index)) + setOffset), smallSize))
                currentIndex += 1
            }
            
            if currentIndex >= blockCount { break }
            
            // 下段 - 3つの小ブロック
            // 最大3つの小ブロックを配置
            for index in 0..<min(3, blockCount - currentIndex) {
                positions.append((CGPoint(x: unitSize * CGFloat(index), y: unitSize * 3 + setOffset), smallSize))
                currentIndex += 1
            }
            
            if currentIndex >= blockCount { break }
            
            // 最下段 - 1つの大ブロック(3x3)
            positions.append((CGPoint(x: 0, y: unitSize * 4 + setOffset), largeSize))
            currentIndex += 1
            
            // 10個のフルセットに満たない場合は継続する必要なし
            if remainingBlocks < 10 {
                break
            }
        }
        
        return positions
    }
}
