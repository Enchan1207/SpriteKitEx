//
//  BallNode.swift
//  SpriteKitEx
//
//  Created by EnchantCode on 2022/06/23.
//

import SpriteKit
import Foundation

class BallNode: SKShapeNode {
    
    /// 半径を指定してボールノードを初期化する
    /// - Parameter radius: ボールの半径
    init(radius: CGFloat){
        super.init()
        
        self.path = .init(ellipseIn: .init(x: -radius, y: -radius, width: 2 * radius, height: 2 * radius), transform: nil)
        self.strokeColor = .clear
        self.fillColor = .white
        
        // 物理状態の設定
        let physicsBody = SKPhysicsBody(circleOfRadius: radius, center: .zero)
        physicsBody.allowsRotation = false      // 回転を許可しない
        physicsBody.friction = 0.0              // 摩擦ゼロ
        physicsBody.restitution = 1.0           // 反発係数1.0
        physicsBody.linearDamping = 0.0         // 線速度ゼロ
        physicsBody.angularDamping = 0.0        // 回転速度ゼロ
        physicsBody.categoryBitMask = NodeCategory.Ball
        physicsBody.contactTestBitMask = NodeCategory.Edge | NodeCategory.Wall | NodeCategory.Paddle
        self.physicsBody = physicsBody
    }
    
    required init?(coder aDecoder: NSCoder) {
        // このノードをNSCoder経由で生成することはないだろう、という想定
        fatalError("init(coder:) has not been implemented")
    }
}
