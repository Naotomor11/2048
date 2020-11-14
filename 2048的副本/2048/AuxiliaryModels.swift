//
//  AuxiliaryModels.swift
//  2048
//
//  Created by 林宇旋 on 2020/10/27.
//  Copyright © 2020 林宇旋. All rights reserved.
//


// 自定义的结构体与枚举
import Foundation

// 方向枚举
enum MoveDirection {
    case up, down, left, right
}

// 命令，滑动后发出移动控制
struct MoveCommand {
    let direction : MoveDirection
    let completion : (Bool) -> ()
}

// 移动命令枚举
enum MoveOrder {
    case singleMoveOrder(source: Int, destination: Int, value: Int, wasMerge: Bool)
    case doubleMoveOrder(firstSource: Int, secondSource: Int, destination: Int, value: Int)
}

// 格子状态枚举
enum TileObject {
    case empty
    case tile(Int)
}

// 中间结果枚举  actiontoken在被发送到委托之前被转换为MoveOrders。
enum ActionToken {
    case noAction(source: Int, value: Int)
    case move(source: Int, value: Int)
    case singleCombine(source: Int, value: Int)
    case doubleCombine(source: Int, second: Int, value: Int)
    
    // 获得值
    func getValue() -> Int {
        switch self {
        case let .noAction(_, v): return v
        case let .move(_, v): return v
        case let .singleCombine(_, v): return v
        case let .doubleCombine(_, _, v): return v
        }
    }
    // 获得分数
    func getSource() -> Int {
        switch self {
        case let .noAction(s, _): return s
        case let .move(s, _): return s
        case let .singleCombine(s, _): return s
        case let .doubleCombine(s, _, _): return s
        }
    }
}

// 正方形棋盘
struct SquareGameboard<T> {
    let dimension : Int
    var boardArray : [T]        //存储Tile类型的数组
    
    init(dimension d: Int, initialValue: T) {
        dimension = d
        boardArray = [T](repeating: initialValue, count: d*d)
    }
    //下标脚本，快速访问boardArray的任意一个元素
    subscript(row: Int, col: Int) -> T {
        get {
            assert(row >= 0 && row < dimension)
            assert(col >= 0 && col < dimension)
            return boardArray[row*dimension + col]
        }
        set {
            assert(row >= 0 && row < dimension)
            assert(col >= 0 && col < dimension)
            boardArray[row*dimension + col] = newValue
        }
    }
    
    mutating func setAll(to item: T) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                self[i, j] = item
            }
        }
    }
}

