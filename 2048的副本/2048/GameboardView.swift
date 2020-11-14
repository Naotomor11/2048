//
//  GameboardView.swift
//  2048
//
//  Created by 林宇旋 on 2020/10/27.
//  Copyright © 2020 林宇旋. All rights reserved.
//

// 游戏面板
import UIKit

class GameboardView: UIView {

    var dimension: Int              //维度
    var tileWidth: CGFloat          //格子宽
    var tilePadding: CGFloat        //格子空隙
    var cornerRadius: CGFloat       //圆角
    var tiles: Dictionary<IndexPath, TileView>      //将格子存为字典
    
    let provider = AppearanceProvider()     // 控制颜色参数
    
    // 动画控制
    let tilePopStartScale: CGFloat = 0.1
    let tilePopMaxScale: CGFloat = 1.1
    let tilePopDelay: TimeInterval = 0.05
    let tileExpandTime: TimeInterval = 0.18
    let tileContractTime: TimeInterval = 0.08
    
    let tileMergeStartScale: CGFloat = 1.0
    let tileMergeExpandTime: TimeInterval = 0.08
    let tileMergeContractTime: TimeInterval = 0.08
    
    let perSquareSlideDuration: TimeInterval = 0.08
    
    // 初始化
    init(dimension d: Int, tileWidth width: CGFloat, tilePadding padding: CGFloat, cornerRadius radius: CGFloat, backgroundColor: UIColor, foregroundColor: UIColor) {
        assert(d > 0)
        dimension = d
        tileWidth = width
        tilePadding = padding
        cornerRadius = radius
        tiles = Dictionary()
        let sideLength = padding + CGFloat(dimension)*(width + padding)
        super.init(frame: CGRect(x: 0, y: 0, width: sideLength, height: sideLength))
        layer.cornerRadius = radius
        setupBackground(backgroundColor: backgroundColor, tileColor: foregroundColor)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    //  重置游戏
    func reset() {
        for (_, tile) in tiles {
            tile.removeFromSuperview()
        }
        tiles.removeAll(keepingCapacity: true)
    }
    
    // 判定是否出边界，（x，y）是否合法
    func positionIsValid(_ pos: (Int, Int)) -> Bool {
        let (x, y) = pos
        return (x >= 0 && x < dimension && y >= 0 && y < dimension)
    }
    // 设置九宫格背景
    func setupBackground(backgroundColor bgColor: UIColor, tileColor: UIColor) {
        backgroundColor = bgColor
        var xCursor = tilePadding
        var yCursor: CGFloat
        let bgRadius = (cornerRadius >= 2) ? cornerRadius - 2 : 0
        for _ in 0..<dimension {
            yCursor = tilePadding
            for _ in 0..<dimension {
                let background = UIView(frame: CGRect(x: xCursor, y: yCursor, width: tileWidth, height: tileWidth))
                background.layer.cornerRadius = bgRadius
                background.backgroundColor = tileColor
                addSubview(background)
                yCursor += tilePadding + tileWidth
            }
            xCursor += tilePadding + tileWidth
        }
    }
    
    // 插入一个框来更新游戏板，将value值插入到pos（x，y）
    func insertTile(at pos: (Int, Int), value: Int) {
        assert(positionIsValid(pos))
        let (row, col) = pos
        let x = tilePadding + CGFloat(col)*(tileWidth + tilePadding)
        let y = tilePadding + CGFloat(row)*(tileWidth + tilePadding)
        let r = (cornerRadius >= 2) ? cornerRadius - 2 : 0
        let tile = TileView(position: CGPoint(x: x, y: y), width: tileWidth, value: value, radius: r, delegate: provider)
        tile.layer.setAffineTransform(CGAffineTransform(scaleX: tilePopStartScale, y: tilePopStartScale))
        
        addSubview(tile)
        bringSubview(toFront: tile)     //将添加到图显示到最前
        tiles[IndexPath(row: row, section: col)] = tile     //插入后添加到tiles字典
        
        // 添加动画
        UIView.animate(withDuration: tileExpandTime, delay: tilePopDelay, options: UIViewAnimationOptions(),
                       animations: {
                        tile.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))  //弹出方框，若无，合并后方框无法在同一直线上
        },
                       completion: { finished in
                        UIView.animate(withDuration: self.tileContractTime, animations: { () -> Void in         //弹出后缩小方块
                            tile.layer.setAffineTransform(CGAffineTransform.identity)
                        })
        })
 
    }
    
    // 通过将一块瓷砖从一个位置移动到另一个位置来更新游戏板。如果移动将把两个瓦片折叠成一个新瓦片，瓦片将在移动到新位置后弹出。
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
        assert(positionIsValid(from) && positionIsValid(to))
        let (fromRow, fromCol) = from       //起始位置
        let (toRow, toCol) = to             //终止位置
        let fromKey = IndexPath(row: fromRow, section: fromCol)
        let toKey = IndexPath(row: toRow, section: toCol)
        
        // 得到起始位置
        guard let tile = tiles[fromKey] else {
            assert(false, "placeholder error")
        }
        let endTile = tiles[toKey]  //终止位置
        
        // 计算目标（x，y）位置
        var finalFrame = tile.frame
        finalFrame.origin.x = tilePadding + CGFloat(toCol)*(tileWidth + tilePadding)
        finalFrame.origin.y = tilePadding + CGFloat(toRow)*(tileWidth + tilePadding)
        
        // 更新棋盘信息
        tiles.removeValue(forKey: fromKey)      //将原来tile删去
        tiles[toKey] = tile         //新tile添加进去
        
        // 出入动画，修改后的棋盘在界面中显示
        let shouldPop = endTile != nil
        UIView.animate(withDuration: perSquareSlideDuration,
                       delay: 0.0,
                       options: UIViewAnimationOptions.beginFromCurrentState,
                       animations: {
                        tile.frame = finalFrame
        },
                       completion: { (finished: Bool) -> Void in
                        tile.value = value
                        endTile?.removeFromSuperview()
                        if !shouldPop || !finished {
                            return
                        }
                        tile.layer.setAffineTransform(CGAffineTransform(scaleX: self.tileMergeStartScale, y: self.tileMergeStartScale))
                        UIView.animate(withDuration: self.tileMergeExpandTime,
                                       animations: {
                                        tile.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))
                        },
                                       completion: { finished in
                                        // 方块缩小到原来大小
                                        UIView.animate(withDuration: self.tileMergeContractTime, animations: {
                                            tile.layer.setAffineTransform(CGAffineTransform.identity)
                                        })
                        })
        })
    }
    
    //将两个方块从原来的位置移动到一个共同的目的地来更新游戏板，移动到目标位置后弹出。
    //先取两个tiles，根据to计算目的位置，移除两个tiles，添加新的tile
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        assert(positionIsValid(from.0) && positionIsValid(from.1) && positionIsValid(to))
        let (fromRowA, fromColA) = from.0       //方块A
        let (fromRowB, fromColB) = from.1       //方块B
        let (toRow, toCol) = to                 //目标位置
        let fromKeyA = IndexPath(row: fromRowA, section: fromColA)
        let fromKeyB = IndexPath(row: fromRowB, section: fromColB)
        let toKey = IndexPath(row: toRow, section: toCol)
        
        guard let tileA = tiles[fromKeyA] else {
            assert(false, "placeholder error")
        }
        guard let tileB = tiles[fromKeyB] else {
            assert(false, "placeholder error")
        }
        
        // 制作框架
        var finalFrame = tileA.frame
        finalFrame.origin.x = tilePadding + CGFloat(toCol)*(tileWidth + tilePadding)
        finalFrame.origin.y = tilePadding + CGFloat(toRow)*(tileWidth + tilePadding)
        
        // 更新棋盘信息
        let oldTile = tiles[toKey]
        oldTile?.removeFromSuperview()
        tiles.removeValue(forKey: fromKeyA)
        tiles.removeValue(forKey: fromKeyB)
        tiles[toKey] = tileA
        
        //出入动画，修改后的棋盘在界面中显示
        UIView.animate(withDuration: perSquareSlideDuration,
                       delay: 0.0,
                       options: UIViewAnimationOptions.beginFromCurrentState,
                       animations: {
                        tileA.frame = finalFrame
                        tileB.frame = finalFrame
        },
                       completion: { finished in
                        tileA.value = value
                        tileB.removeFromSuperview()
                        if !finished {
                            return
                        }
                        tileA.layer.setAffineTransform(CGAffineTransform(scaleX: self.tileMergeStartScale, y: self.tileMergeStartScale))
                        UIView.animate(withDuration: self.tileMergeExpandTime,
                                       animations: {
                                        tileA.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))
                        },
                                       completion: { finished in
                                        UIView.animate(withDuration: self.tileMergeContractTime, animations: {
                                            tileA.layer.setAffineTransform(CGAffineTransform.identity)
                                        })
                        })
        })
    }

}
