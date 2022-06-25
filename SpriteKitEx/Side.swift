//
//  Side.swift
//  SpriteKitEx
//
//  Created by EnchantCode on 2022/06/25.
//

import Foundation

enum Side {
    case Player
    case Computer
    
    func opposite() -> Side {
        return (self == .Player) ? .Computer : .Player
    }
}
