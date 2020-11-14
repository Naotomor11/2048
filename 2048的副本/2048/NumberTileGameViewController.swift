//
//  NumberTileGameViewController.swift
//  2048
//
//  Created by 林宇旋 on 2020/10/28.
//  Copyright © 2020 林宇旋. All rights reserved.
//

import UIKit
import AVFoundation
//视图控制器。将GameModel和GameboradView联系，
//用户输入到达视图控制器并转发给模型。由模型计算出的移动命令返回到视图控制器并转发到gameboard视图，后者执行任何动画来更新其状态。
class NumberTileGameViewController : UIViewController, GameModelProtocol {
    var dimension: Int
    var threshold: Int     //获胜分
    
    var board: GameboardView?
    var model: GameModel?
    
    var scoreView: ScoreViewProtocol?
    
    // 游戏板宽
    let boardWidth: CGFloat = 230.0
    // 方块之间的间隔
    let thinPadding: CGFloat = 3.0
    let thickPadding: CGFloat = 6.0
    
    // 游戏板和分数视图之间的空间大小
    let viewPadding: CGFloat = 10.0
    
    let verticalViewOffset: CGFloat = 0.0
    
    init(dimension d: Int, threshold t: Int) {
        dimension = d > 2 ? d : 2
        threshold = t > 8 ? t : 8
        super.init(nibName: nil, bundle: nil)
        model = GameModel(dimension: dimension, threshold: threshold, delegate: self)
        view.backgroundColor = UIColor.white
        setupSwipeControls()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    func setupSwipeControls() {
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(NumberTileGameViewController.upCommand(_:)))
        upSwipe.numberOfTouchesRequired = 1
        upSwipe.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(upSwipe)
        
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(NumberTileGameViewController.downCommand(_:)))
        downSwipe.numberOfTouchesRequired = 1
        downSwipe.direction = UISwipeGestureRecognizerDirection.down
        view.addGestureRecognizer(downSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(NumberTileGameViewController.leftCommand(_:)))
        leftSwipe.numberOfTouchesRequired = 1
        leftSwipe.direction = UISwipeGestureRecognizerDirection.left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(NumberTileGameViewController.rightCommand(_:)))
        rightSwipe.numberOfTouchesRequired = 1
        rightSwipe.direction = UISwipeGestureRecognizerDirection.right
        view.addGestureRecognizer(rightSwipe)
    }
    
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        setupGame()
    }
    
    // 重开游戏
    func reset() {
        assert(board != nil && model != nil)
        let b = board!
        let m = model!
        b.reset()
        m.reset()
        m.insertTileAtRandomLocation(withValue: 2)
        m.insertTileAtRandomLocation(withValue: 2)
    }
    // 游戏初始化
    func setupGame() {
        let vcHeight = view.bounds.size.height
        let vcWidth = view.bounds.size.width
        
        // x自适应屏幕，得到x
        func xPositionToCenterView(_ v: UIView) -> CGFloat {
            let viewWidth = v.bounds.size.width
            let tentativeX = 0.5*(vcWidth - viewWidth)
            return tentativeX >= 0 ? tentativeX : 0
        }
        
        // y自适应屏幕，得到y
        func yPositionForViewAtPosition(_ order: Int, views: [UIView]) -> CGFloat {
            assert(views.count > 0)
            assert(order >= 0 && order < views.count)
            let totalHeight = CGFloat(views.count - 1)*viewPadding + views.map({ $0.bounds.size.height }).reduce(verticalViewOffset, { $0 + $1 })   //所有控件高度之和
            let viewsTop = 0.5*(vcHeight - totalHeight) >= 0 ? 0.5*(vcHeight - totalHeight) : 0     //整个view的起点
            
            var acc: CGFloat = 0
            for i in 0..<order {
                acc += viewPadding + views[i].bounds.size.height
            }
            return viewsTop + acc
        }
        
        // 分数视图
        let scoreView = ScoreView(backgroundColor: UIColor.black,
                                  textColor: UIColor.white,
                                  font: UIFont(name: "HelveticaNeue-Bold", size: 16.0) ?? UIFont.systemFont(ofSize: 16.0),
                                  radius: 6)
        scoreView.score = 0
        
        // 创建棋盘
        let padding: CGFloat = dimension > 5 ? thinPadding : thickPadding
        let v1 = boardWidth - padding*(CGFloat(dimension + 1))
        let width: CGFloat = CGFloat(floorf(CFloat(v1)))/CGFloat(dimension)
        let gameboard = GameboardView(dimension: dimension,
                                      tileWidth: width,
                                      tilePadding: padding,
                                      cornerRadius: 6,
                                      backgroundColor: UIColor.black,
                                      foregroundColor: UIColor.darkGray)
        
        // 设置框架
        let views = [scoreView, gameboard]
        
        var f = scoreView.frame
        f.origin.x = xPositionToCenterView(scoreView)
        f.origin.y = yPositionForViewAtPosition(0, views: views)
        scoreView.frame = f
        
        f = gameboard.frame
        f.origin.x = xPositionToCenterView(gameboard)
        f.origin.y = yPositionForViewAtPosition(1, views: views)
        gameboard.frame = f
        
        
        // 添加游戏状态
        view.addSubview(gameboard)
        board = gameboard
        view.addSubview(scoreView)
        self.scoreView = scoreView
        
        assert(model != nil)
        let m = model!
        m.insertTileAtRandomLocation(withValue: 2)
        m.insertTileAtRandomLocation(withValue: 2)
    }
    // 每一次成功移动tileView后判定游戏是否结束，没有结束则随机生成一个tileview
    func followUp() {
        assert(model != nil)
        let m = model!
        let (userWon, _) = m.userHasWon()
        if userWon {
            // 胜利
            let alertView = UIAlertView()
            alertView.title = "Victory"
            alertView.message = "You won!"
            alertView.addButton(withTitle: "Cancel")
            alertView.show()
            return
        }
        
        // 插入方块
        let randomVal = Int(arc4random_uniform(10))
        m.insertTileAtRandomLocation(withValue: randomVal == 1 ? 4 : 2)
        
        // 插入后可能失败
        if m.userHasLost() {
            NSLog("You lost...")
            let alertView = UIAlertView()
            alertView.title = "Defeat"
            alertView.message = "You lost..."
            alertView.addButton(withTitle: "Cancel")
            alertView.show()
        }
    }
    
    let soundArray = ["note1","note2","note3","note4"]
    
    // 移动命令
    //上
    @objc(up:)
    func upCommand(_ r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.up,
                    onCompletion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
        let selectSoundFileName = soundArray[0]
        playSound(selectSoundFileName)
    }
    //下
    @objc(down:)
    func downCommand(_ r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.down,
                    onCompletion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
        let selectSoundFileName = soundArray[1]
        playSound(selectSoundFileName)
    }
    //左
    @objc(left:)
    func leftCommand(_ r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.left,
                    onCompletion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
        let selectSoundFileName = soundArray[2]
        playSound(selectSoundFileName)
    }
    //右
    @objc(right:)
    func rightCommand(_ r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.right,
                    onCompletion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
        let selectSoundFileName = soundArray[3]
        playSound(selectSoundFileName)
    }
    
    
    func scoreChanged(to score: Int) {
        if scoreView == nil {
            return
        }
        let s = scoreView!
        s.scoreChanged(to: score)
    }
    
    //移动一个方块
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
        assert(board != nil)
        let b = board!
        b.moveOneTile(from: from, to: to, value: value)
    }
    
    //移动两个方块
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        assert(board != nil)
        let b = board!
        b.moveTwoTiles(from: from, to: to, value: value)
    }
    
    //插入方块
    func insertTile(at location: (Int, Int), withValue value: Int) {
        assert(board != nil)
        let b = board!
        b.insertTile(at: location, value: value)
    }
}

// 播放声音
var audioPlayer : AVAudioPlayer!
private func playSound(_ soundFileName : String){
    
    let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "wav")
    
    do{
        try  audioPlayer = AVAudioPlayer(contentsOf: soundURL!)
        
    }catch{
        print(error.localizedDescription)
    }
    
    audioPlayer.play()
    
}
