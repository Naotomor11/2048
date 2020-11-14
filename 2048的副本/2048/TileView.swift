//
//  TileView.swift
//  2048
//
//  Created by 林宇旋 on 2020/10/27.
//  Copyright © 2020 林宇旋. All rights reserved.
//

import UIKit

class TileView: UIView {
    // 每个框的值
    var value : Int = 0 {
        didSet {        //属性观察
            backgroundColor = delegate.tileColor(value)
            numberLabel.textColor = delegate.numberColor(value)
            numberLabel.text = "\(value)"
        }
    }
    
    unowned let delegate : AppearanceProviderProtocol   //改色
    let numberLabel : UILabel
    
    init(position: CGPoint, width: CGFloat, value: Int, radius: CGFloat, delegate d: AppearanceProviderProtocol) {
        delegate = d
        numberLabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: width))
        numberLabel.textAlignment = NSTextAlignment.center  //文字对齐
        numberLabel.minimumScaleFactor = 0.5        //最小字体
        numberLabel.font = delegate.fontForNumbers()    //标题大小
        
        super.init(frame: CGRect(x: position.x, y: position.y, width: width, height: width))
        addSubview(numberLabel)         // 向上加label
        layer.cornerRadius = radius     //圆角
        
        self.value = value
        backgroundColor = delegate.tileColor(value)         //背景色
        numberLabel.textColor = delegate.numberColor(value)       //字体颜色
        numberLabel.text = "\(value)"       //字
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

}
