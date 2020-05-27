//
//  ViewController.swift
//  Mochi Games
//
//  Created by Sam Weekes on 5/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import UIKit

class ViewController : UIViewController {
    override var prefersStatusBarHidden: Bool { return true }
    
    var gameInterface : MochiGameInterface?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        
        gameInterface = MochiGameInterface()
        gameInterface?.setUpGame()
        self.view.addSubview(gameInterface!.view)
        
        
    }
    
    
}


// !! - any UI that is to be added to the game but doesn't want to be recorded will be added to MochiGameInterface().nonRecordView
