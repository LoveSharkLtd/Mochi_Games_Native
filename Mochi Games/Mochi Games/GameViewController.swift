//
//  ViewController.swift
//  Mochi Games
//
//  Created by Sam Weekes on 4/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import UIKit
import SpriteKit
import ReplayKit
import GameplayKit

class GameViewController: UIViewController, CameraDelegate {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateScreenScales()
        
        
        
    }

    func cameraSessionDidBegin() {
        // Called when the camera session has started
    }
    
    func didUpdatePixelBuffer(pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription) {
        // this is called each frame and the MTLCameraView is needed to be passed the pixelbuffer and the formatdescription
    }
    
    
}


// - hiderViewController is used to attach to the secondary UIWindow which will house all the UI elements that do not want to be included in the recording
class hiderViewController : UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

// - These are just cause I like having animated buttons lol
extension UIViewController {
    @objc func ButtonDown(_ sender : UIButton) {
        let bg = sender.subviews[1]
        UIView.animate(withDuration: 0.125, delay: 0.0, options: .curveEaseIn, animations: {
            bg.frame.origin.y = sHR * 3 / 667
        }) { (_) in
            //
        }
    }
    
    @objc func ButtonUp(_ sender : UIButton) {
        let bg = sender.subviews[1]
        UIView.animate(withDuration: 0.125, delay: 0.0, options: .curveEaseIn, animations: {
            bg.frame.origin.y = 0.0
        }) { (_) in
            //
        }
    }
}
