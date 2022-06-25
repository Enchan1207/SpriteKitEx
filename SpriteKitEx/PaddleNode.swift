//
//  PaddleNode.swift
//  SpriteKitEx
//
//  Created by EnchantCode on 2022/06/23.
//

import SpriteKit
import Foundation

class PaddleNode: SKShapeNode {
    
    /// サイズを指定してパドルノードを初期化する
    /// - Parameter size: パドルのサイズ
    init(size: CGSize){
        super.init()
        
        self.path = .init(rect: .init(origin: .init(x: -size.width / 2, y: -size.height / 2), size: size), transform: nil)
        self.strokeColor = .clear
        self.fillColor = .white
        
        // 物理状態の設定
        let physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody.allowsRotation = false      // 回転を許可しない
        physicsBody.friction = 0.0              // 摩擦ゼロ
        physicsBody.restitution = 1.0           // 反発係数1.0
        physicsBody.linearDamping = 0.0         // 線速度ゼロ
        physicsBody.angularDamping = 0.0        // 回転速度ゼロ
        physicsBody.isDynamic = false           // 動かない
        physicsBody.categoryBitMask = NodeCategory.Paddle
        
        self.physicsBody = physicsBody
    }
    
    required init?(coder aDecoder: NSCoder) {
        // このノードをNSCoder経由で生成することはないだろう、という想定
        fatalError("init(coder:) has not been implemented")
    }
}

