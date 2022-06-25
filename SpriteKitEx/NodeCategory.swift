//
//  NodeCategory.swift
//  SpriteKitEx
//
//  Created by EnchantCode on 2022/06/24.
//

import Foundation

struct NodeCategory {
    static let Ball: UInt32         = 0b0000_0001
    static let Paddle: UInt32       = 0b0000_0010
    static let Wall: UInt32         = 0b0001_0000
    static let PlayerEdge: UInt32   = 0b0010_0000
    static let ComputerEdge: UInt32 = 0b0100_0000
    static let Edge: UInt32         = 0b1000_0000
}
