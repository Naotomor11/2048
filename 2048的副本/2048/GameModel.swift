//
//  GameModel.swift
//  2048
//
//  Created by 林宇旋 on 2020/10/27.
//  Copyright © 2020 林宇旋. All rights reserved.
//

// 移动合并算法实现
import UIKit

// 协议定义
protocol GameModelProtocol : class {
    func scoreChanged(to score: Int)
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int)
    func insertTile(at location: (Int, Int), withValue value: Int)
}

class GameModel: NSObject {
    let dimension : Int         //维度
    let threshold : Int         //目标分数
    
    var score : Int = 0 {
        didSet {        //属性观察
            delegate.scoreChanged(to: score)
        }
    }
    var gameboard: SquareGameboard<TileObject>
    
    unowned let delegate : GameModelProtocol
    
    var queue: [MoveCommand]    //表示本次滑动方向，移动后该做什么
    var timer: Timer            //定时器，防止滑动过快
    
    let maxCommands = 100
    let queueDelay = 0.3
    
    init(dimension d: Int, threshold t: Int, delegate: GameModelProtocol) {
        dimension = d
        threshold = t
        self.delegate = delegate
        queue = [MoveCommand]()
        timer = Timer()
        gameboard = SquareGameboard(dimension: d, initialValue: .empty)
        super.init()
    }
    
    //  重开游戏
    func reset() {
        score = 0
        gameboard.setAll(to: .empty)
        queue.removeAll(keepingCapacity: true)
        timer.invalidate()
    }
    
    // 执行移动。队列强制在每次移动之间有几毫秒的延迟。
    func queueMove(direction: MoveDirection, onCompletion: @escaping (Bool) -> ()) {
        queue.append(MoveCommand(direction: direction, completion: onCompletion))
        if !timer.isValid {
            timerFired(timer)
        }
    }

    // 判断后调用performMove准备进行移动，若有发生移动，则重新启动定时器.
    @objc func timerFired(_: Timer) {
        if queue.count == 0 {
            return
        }
        // 遍历队列，直到遇到有效指令或者遍历完
        var changed = false
        while queue.count > 0 {
            let command = queue[0]
            queue.remove(at: 0)
            changed = performMove(direction: command.direction)
            command.completion(changed)
            if changed {
                break
            }
        }
        if changed {        //重启定时器
            timer = Timer.scheduledTimer(timeInterval: queueDelay,
                                         target: self,
                                         selector:
                #selector(GameModel.timerFired(_:)),
                                         userInfo: nil,
                                         repeats: false)
        }
    }
    
    // 插入一个给定值的方块。
    func insertTile(at location: (Int, Int), value: Int) {
        let (x, y) = location
        if case .empty = gameboard[x, y] {
            gameboard[x, y] = TileObject.tile(value)
            delegate.insertTile(at: location, withValue: value)
        }
    }
    
    /// 在任意位置插入一个给定值的方块
    func insertTileAtRandomLocation(withValue value: Int) {
        let openSpots = gameboardEmptySpots()
        if openSpots.isEmpty {
            return
        }
        // 随机选择一个空格，并放置一个新的方块
        let idx = Int(arc4random_uniform(UInt32(openSpots.count-1)))
        let (x, y) = openSpots[idx]
        insertTile(at: (x, y), value: value)
    }
    
    // 返回游戏板上空的格子的集合
    func gameboardEmptySpots() -> [(Int, Int)] {
        var buffer : [(Int, Int)] = []
        for i in 0..<dimension {
            for j in 0..<dimension {
                if case .empty = gameboard[i, j] {
                    buffer += [(i, j)]
                }
            }
        }
        return buffer
    }
    
    // （x，y）（x，y+1）是否有相同值
    func tileBelowHasSameValue(location: (Int, Int), value: Int) -> Bool {
        let (x, y) = location
        guard y != dimension - 1 else {
            return false
        }
        if case let .tile(v) = gameboard[x, y+1] {
            return v == value
        }
        return false
    }
    // （x，y）（x+1，y）是否有相同值
    func tileToRightHasSameValue(location: (Int, Int), value: Int) -> Bool {
        let (x, y) = location
        guard x != dimension - 1 else {
            return false
        }
        if case let .tile(v) = gameboard[x+1, y] {
            return v == value
        }
        return false
    }
    // 游戏结束判定
    func userHasLost() -> Bool {
        guard gameboardEmptySpots().isEmpty else {
            return false
        }
        
        // 检查所有可能的走a法
        for i in 0..<dimension {
            for j in 0..<dimension {
                switch gameboard[i, j] {
                case .empty:
                    assert(false, "Gameboard reported itself as full, but we still found an empty tile. This is a logic error.")
                case let .tile(v):
                    if tileBelowHasSameValue(location: (i, j), value: v) || tileToRightHasSameValue(location: (i, j), value: v)
                    {
                        return false
                    }
                }
            }
        }
        return true
    }
    //游戏获胜判定
    func userHasWon() -> (Bool, (Int, Int)?) {
        for i in 0..<dimension {
            for j in 0..<dimension {
                // 找2048格
                if case let .tile(v) = gameboard[i, j], v >= threshold {
                    return (true, (i, j))
                }
            }
        }
        return (false, nil)
    }
    

    // 执行单个移动的所有计算和更新状态。
    func performMove(direction: MoveDirection) -> Bool {
        let coordinateGenerator: (Int) -> [(Int, Int)] = { (iteration: Int) -> [(Int, Int)] in
            var buffer = Array<(Int, Int)>(repeating: (0, 0), count: self.dimension)
            for i in 0..<self.dimension {
                switch direction {
                case .up: buffer[i] = (i, iteration)
                case .down: buffer[i] = (self.dimension - i - 1, iteration)
                case .left: buffer[i] = (iteration, i)
                case .right: buffer[i] = (iteration, self.dimension - i - 1)
                }
            }
            return buffer       //根据滑动方向返回滑动顺序
        }
        
        var atLeastOneMove = false
        for i in 0..<dimension {
            let coords = coordinateGenerator(i)     // 移动的顺序存放在coords中
            
            let tiles = coords.map() { (c: (Int, Int)) -> TileObject in
                let (x, y) = c
                return self.gameboard[x, y]
            }
            
            // 执行移动操作
            let orders = merge(tiles)
            atLeastOneMove = orders.count > 0 ? true : atLeastOneMove
            
            // 写回结果
            for object in orders {
                switch object {
                case let MoveOrder.singleMoveOrder(s, d, v, wasMerge):
                    // 执行单次移动
                    let (sx, sy) = coords[s]
                    let (dx, dy) = coords[d]
                    if wasMerge {
                        score += v  //触发属性观察器
                    }
                    gameboard[sx, sy] = TileObject.empty        //更新面板
                    gameboard[dx, dy] = TileObject.tile(v)
                    
                    //改变UI
                    delegate.moveOneTile(from: coords[s], to: coords[d], value: v)
                case let MoveOrder.doubleMoveOrder(s1, s2, d, v):
                    // 执行两格子移动
                    let (s1x, s1y) = coords[s1]
                    let (s2x, s2y) = coords[s2]
                    let (dx, dy) = coords[d]
                    score += v
                    gameboard[s1x, s1y] = TileObject.empty
                    gameboard[s2x, s2y] = TileObject.empty
                    gameboard[dx, dy] = TileObject.tile(v)
                    delegate.moveTwoTiles(from: (coords[s1], coords[s2]), to: coords[d], value: v)
                }
            }
        }
        return atLeastOneMove
    }
    
    
    // merge( condense -> collapse -> convert)
    // 先移动后合并， 先将两个要合并的方块，一个删除，一个改变值
    
    
    // 压缩，移动时候将中间的空格压缩， 如[2][][][8] 变成 [2][8][][]
    func condense(_ group: [TileObject]) -> [ActionToken] {     //ActionToken中装tile原位置
        var tokenBuffer = [ActionToken]()
        for (idx, tile) in group.enumerated() {
            switch tile {
            case let .tile(value) where tokenBuffer.count == idx:       //四个格子都有值
                tokenBuffer.append(ActionToken.noAction(source: idx, value: value))
            case let .tile(value):          //一旦出现空格，调用这个
                tokenBuffer.append(ActionToken.move(source: idx, value: value))
            default:
                break
            }
        }
        return tokenBuffer;     //tokenBuffer装有所有tile执行的操作，
    }
    
    class func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
        // 返回“NoAction”标记是否仍然表示未移动的块
        return (inputPosition == outputLength) && (originalPosition == inputPosition)
    }
    
    // 合并相同数值的格子    [2][2][4][8] -> [4][][4][8]
    func collapse(_ group: [ActionToken]) -> [ActionToken] {
        
        var tokenBuffer = [ActionToken]()
        var skipNext = false        //是否跳过下一个格子，如果本次合并，那么跳过下一个格子（已经为空）
        for (idx, token) in group.enumerated() {
            if skipNext {
                skipNext = false
                continue
            }
            switch token {
            case .singleCombine:
                assert(false, "Cannot have single combine token in input")
            case .doubleCombine:
                assert(false, "Cannot have double combine token in input")
            case let .noAction(s, v)
                where (idx < group.count-1
                    && v == group[idx+1].getValue()
                    && GameModel.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s)):
                // 移动+合并  [2][2][4][4] -> [4][][4][4] -> [4][8][][]
                let next = group[idx+1]
                let nv = v + group[idx+1].getValue()
                skipNext = true
                tokenBuffer.append(ActionToken.singleCombine(source: next.getSource(), value: nv))
            case let t where (idx < group.count-1 && t.getValue() == group[idx+1].getValue()):
                let next = group[idx+1]
                let nv = t.getValue() + group[idx+1].getValue()
                skipNext = true
                tokenBuffer.append(ActionToken.doubleCombine(source: t.getSource(), second: next.getSource(), value: nv))
                
            case let .noAction(s, v) where !GameModel.quiescentTileStillQuiescent(inputPosition: idx, outputLength: tokenBuffer.count, originalPosition: s):
                // 移动不合并。[2][2][][] -> [4][][][]
                tokenBuffer.append(ActionToken.move(source: s, value: v))
            case let .noAction(s, v):
                // 不移动，不合并  [2][4][8][2] -> [2][4][8][2]
                tokenBuffer.append(ActionToken.noAction(source: s, value: v))
            case let .move(s, v):
                // 只移动  [2][][4][8] -> [2][4][8][]
                tokenBuffer.append(ActionToken.move(source: s, value: v))
            default:
                break
            }
        }
        return tokenBuffer
    }
    
    // 得到通过condense和convert方法的actiontoken列表，将它们转换为MoveOrders。
    func convert(_ group: [ActionToken]) -> [MoveOrder] {
        var moveBuffer = [MoveOrder]()
        for (idx, t) in group.enumerated() {
            switch t {
            case let .move(s, v):
                moveBuffer.append(MoveOrder.singleMoveOrder(source: s, destination: idx, value: v, wasMerge: false))
            case let .singleCombine(s, v):
                moveBuffer.append(MoveOrder.singleMoveOrder(source: s, destination: idx, value: v, wasMerge: true))
            case let .doubleCombine(s1, s2, v):
                moveBuffer.append(MoveOrder.doubleMoveOrder(firstSource: s1, secondSource: s2, destination: idx, value: v))
            default:
                break
            }
        }
        return moveBuffer
    }
    

    func merge(_ group: [TileObject]) -> [MoveOrder] {
        return convert(collapse(condense(group)))
    }
}

/*
 计算过程分为三个步骤:
1。计算产生相同贴图但没有任何间隔空间的移动。
2。取上面的值，并计算折叠相等的相邻块所需要的移动。
3。接受上面的命令，并将其转换为MoveOrders，它将为委托提供所有必要的信息。
 */
