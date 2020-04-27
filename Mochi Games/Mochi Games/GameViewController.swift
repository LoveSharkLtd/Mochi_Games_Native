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

class GameViewController: UIViewController, CameraDelegate, RPPreviewViewControllerDelegate {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    var vidPlayer : AVPlayer?
    var nonRecordWindow : UIWindow!
    
    var previewVideo : MTLCameraView?
    var BackgroundVideo : MTLCameraView?
    
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateScreenScales()
        
        BackgroundVideo = MTLCameraView.init(frame: CGRect(), device: MTLCreateSystemDefaultDevice())
        BackgroundVideo?.frame = CGRect(x: 0.0, y: 0.0, width: sW, height: sH)

        self.view.addSubview(BackgroundVideo!)
        
        
        Camera.shared().delegate = self
        Camera.shared().setUp()
        
        // - Game Scene
        
        let skview = SKView(frame: CGRect(x: 0.0, y: 0.0, width: sW, height: sH))
        skview.allowsTransparency = true

        let scene = GameScene()
        scene.scaleMode = .aspectFill
        scene.backgroundColor = .clear
        skview.presentScene(scene)

        skview.ignoresSiblingOrder = true
        skview.showsFPS = true
        skview.showsNodeCount = true

        view.addSubview(skview)
        
        nonRecordWindow = UIWindow(frame: self.view.frame)
        nonRecordWindow.rootViewController = hiderViewController()
        
        
        let h = sHR * 150 / 667
        let w = h * sW / sH
        let _h = h + sHR * 6 / 667
        let _w = w + sHR * 6 / 667
        
        let gap = sHR * 20 / 667
        let borderRadius = sHR * 6 / 667
        
        let bg = UIView(frame: CGRect(x: 0.0, y: 0.0, width: _w, height: _h))
        bg.center = CGPoint(x: sW - gap - 0.5 * w, y: gap + 0.5 * h)
        bg.backgroundColor = .black
        bg.layer.cornerRadius = borderRadius * 1.3
        bg.layer.masksToBounds = true
        
        
        previewVideo = MTLCameraView.init(frame: CGRect(), device: MTLCreateSystemDefaultDevice())
        previewVideo?.frame = CGRect(x: 0.0, y: 0.0, width: w, height: h)
        previewVideo?.center = CGPoint(x: sW - gap - 0.5 * w, y: gap + 0.5 * h)
        previewVideo?.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        previewVideo?.layer.cornerRadius = borderRadius
        previewVideo?.layer.masksToBounds = true
        
        let W = sH * 576 / 1024
        let tiktokVideo = UIView(frame: CGRect(x: 0.0, y: 0.0, width: W, height: sH))
        tiktokVideo.backgroundColor = .blue
        
        
        let videoURL = Bundle.main.url(forResource: "Grimes_v3", withExtension: "mp4")
        vidPlayer = AVPlayer(url: videoURL!)
        vidPlayer?.actionAtItemEnd = .none
        
        let videoLayer = AVPlayerLayer(player: vidPlayer!)
        videoLayer.frame = (tiktokVideo.frame)
        videoLayer.videoGravity = .resizeAspectFill
        tiktokVideo.layer.addSublayer(videoLayer)
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.vidPlayer?.currentItem, queue: .main) { _ in
                self.vidPlayer?.seek(to: CMTime.zero)
                self.vidPlayer?.play()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { (_) in
            self.vidPlayer?.play()
        }
        
        vidPlayer?.play()
        tiktokVideo.center = CGPoint(x: sW * 0.5, y: sH * 0.5)
        
        let h_ = sHR * 50 / 667
        let w_ = _deviceType == .iPad ? sHR * 356 / 667 : sW - sHR * 20 / 667
        let g = sHR * 10 / 667
        
        var recBtn = createButton(width: w_, height: h_, title: "Record", textSize: sHR * 16 / 667)
        recBtn.center = CGPoint(x: sW * 0.5, y: sH - h_ - g - g)
        recBtn.addTarget(self, action: #selector(ButtonDown(_:)), for: .touchDown)
        recBtn.addTarget(self, action: #selector(ButtonUp(_:)), for: .touchUpOutside)
        recBtn.addTarget(self, action: #selector(recBtnUp(_:)), for: .touchUpInside)
        
        nonRecordWindow.rootViewController?.view.addSubview(tiktokVideo)
        nonRecordWindow.rootViewController?.view.addSubview(bg)
        nonRecordWindow.rootViewController?.view.addSubview(recBtn)
        nonRecordWindow.rootViewController?.view.addSubview(previewVideo!)
        
        nonRecordWindow.makeKeyAndVisible()
    }
    
    @objc func recBtnUp(_ sender : UIButton) {
        ButtonUp(sender)
        isRecording ? stopRecording() : startRecording()
        if isRecording { self.vidPlayer?.pause() }
        isRecording = !isRecording
    }
    
    func startRecording() {
//        RPScreenRecorder.shared().isMicrophoneEnabled = true
        RPScreenRecorder.shared().startRecording { (_) in
            print("!! - rec started")
        }

    }
    
    func stopRecording() {
        RPScreenRecorder.shared().stopRecording { (preview, err) in
            self.vidPlayer?.pause()
            guard let preview = preview else { return }
            
            preview.previewControllerDelegate = self
            self.nonRecordWindow.rootViewController?.present(preview, animated: true) {
            
            }
        }
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true) {
            self.vidPlayer?.play()
        }
    }

    func cameraSessionDidBegin() {
        // Called when the camera session has started
    }
    
    func didUpdatePixelBuffer(pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription) {
        // this is called each frame and the MTLCameraView is needed to be passed the pixelbuffer and the formatdescription
        
        self.previewVideo?.pixelBuffer = pixelBuffer
        self.BackgroundVideo?.pixelBuffer = pixelBuffer
        self.BackgroundVideo?.formatDescription = formatDescription
        
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
