//
//  ViewController.swift
//  Mochi Games
//
//  Created by Sam Weekes on 5/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import AVFoundation // !! - TBD
import UIKit

class ViewController : UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    var gameInterface : MochiGameInterface?
    var isRecording = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        
        gameInterface = MochiGameInterface()
        gameInterface?.setUpGame()
        self.view.addSubview(gameInterface!.view!)
        
        let btn = UIButton(frame: CGRect(x: 0.0, y: sH - 300, width: sW, height: 300))
        btn.backgroundColor = .red
        btn.addTarget(self, action: #selector(rec), for: .touchUpInside)
        
        gameInterface?.nonRecordView?.addSubview(btn)
        gameInterface?.nonRecordWindow?.makeKeyAndVisible()
    }
    
    @objc func rec() {
        print("!! - \(isRecording ? "stop rec" : "start rec")")
        
        
        if isRecording {
            self.gameInterface?.stopRecording()
            addVideo()
        } else {
            self.gameInterface?.startRecording()
        }
        isRecording = !isRecording
    }
    
    var vidPlayer : AVPlayer?
    
    func addVideo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let url = self.gameInterface?.recorder.outputURL else {
                self.addVideo()
                return
            }
            
            let tiktokVideo = UIView(frame: CGRect(x: 0.0, y: 0.0, width: sW, height: sH))
            tiktokVideo.backgroundColor = .blue
            self.gameInterface?.nonRecordView?.addSubview(tiktokVideo)
            
            self.vidPlayer = AVPlayer(url: url)
            self.vidPlayer?.actionAtItemEnd = .none
            
            let videoLayer = AVPlayerLayer(player: self.vidPlayer!)
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
            
            self.vidPlayer?.play()
            tiktokVideo.center = CGPoint(x: sW * 0.5, y: sH * 0.5)
            
        }
    }
    
}


// !! - any UI that is to be added to the game but doesn't want to be recorded will be added to MochiGameInterface().nonRecordView
