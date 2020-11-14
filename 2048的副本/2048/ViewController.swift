//
//  ViewController.swift
//  2048
//
//  Created by 林宇旋 on 2020/10/27.
//  Copyright © 2020 林宇旋. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


    @IBAction func GameStart(_ sender: UIButton) {
        let game = NumberTileGameViewController(dimension: 4, threshold: 2048)
        self.present(game, animated: true, completion: nil)
    }
}

