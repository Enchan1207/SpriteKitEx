//
//  EdgeNode.swift
//  SpriteKitEx
//
//  Created by EnchantCode on 2022/06/24.
//

import SpriteKit
import Foundation

class EdgeNode: SKShapeNode {
    
    /// サイズを指定してエッジノードを初期化する
    /// - Parameter length: エッジ長
    init(length: CGFloat){
        super.init()
        
        let edgeRect: CGRect = .init(origin: .init(x: -length/2, y: 0), size: .init(width: length, height: 1))
        
        self.path = .init(rect: edgeRect, transform: nil)
        self.strokeColor = .clear
        self.fillColor = .clear
        
        // 物理状態の設定
        let physicsBody = SKPhysicsBody(edgeLoopFrom: edgeRect)
        physicsBody.categoryBitMask = NodeCategory.Edge
        physicsBody.isDynamic = false
        self.physicsBody = physicsBody
    }
    
    required init?(coder aDecoder: NSCoder) {
        // このノードをNSCoder経由で生成することはないだろう、という想定
        fatalError("init(coder:) has not been implemented")
    }
}

