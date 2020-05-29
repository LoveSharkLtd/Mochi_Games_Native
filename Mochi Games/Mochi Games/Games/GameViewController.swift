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

class GameViewController: UIViewController, RPPreviewViewControllerDelegate {
    
    override var prefersStatusBarHidden: Bool { return true }
    
    var vidPlayer : AVPlayer?
    var nonRecordWindow : UIWindow!
    
    var previewVideo : MTLCameraView?
    var BackgroundVideo : MTLCameraView?
    
    var cvInterface = CVInterface()
    
    var isRecording = false
    
    var delegate : GameViewControllerDelegate?
    
    var handsUpBool : Bool = false
    var BLBool : Bool = false
    var BRBool : Bool = false
    
    func setUpGameScene() {
       let skview = SKView(frame: CGRect(x: 0.0, y: 0.0, width: sW, height: sH))
       skview.allowsTransparency = true
        if let scene = SKScene(fileNamed: "DanceScene") {
            scene.scaleMode = .aspectFill
            skview.presentScene(scene)
            (scene as! GameScene).viewController = self
        }
       skview.ignoresSiblingOrder = true
       skview.showsFPS = true
       skview.showsNodeCount = true
       view.addSubview(skview)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateScreenScales()
        
        BackgroundVideo = MTLCameraView.init(frame: CGRect(), device: MTLCreateSystemDefaultDevice())
        BackgroundVideo?.frame = CGRect(x: 0.0, y: 0.0, width: sW, height: sH)

        self.view.addSubview(BackgroundVideo!)
        
        cvInterface.cvInterfaceDelegate = self
        
        // - Game Scene
       
        setUpGameScene()
        
//        setUpNonRecordUI()
        
        cvInterface.loadAll()
    }
    
    func setUpNonRecordUI() {
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
    
//    @objc func tapped(_ gesture: UITapGestureRecognizer) {
//            // !! - use this until we can add these calls to the game
//            self.BackgroundVideo?.toggleFiltering()
//        }
    
    func cameraSessionDidBegin() {
        // Called when the camera session has started
    }
}

protocol GameViewControllerDelegate {
    func handsupDataChanged(handsUp : Bool)
    func brushedShoulderDataChanged(brushedLeftShoulder : Bool, brushedRightShoulder : Bool)
    func didUpdateBodyTrackingData(bodyTrackingData : BodyTrackingData)
    func didUpdateFaceTrackingData(faceTrackingData : FaceDetectionData)
}

// - hiderViewController is used to attach to the secondary UIWindow which will house all the UI elements that do not want to be included in the recording
class hiderViewController : UIViewController {
    
    override var prefersStatusBarHidden: Bool { return true }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension GameViewController: CVInterfaceDelegate {
    func didUpdateGestureRecognitionData(gestureRecognitionData: GestureRecongnitionInformation) {
//        <#code#>
    }
    
    func didUpdatePoseEstimationData(bodyTrackingData: BodyTrackingData, gestureInformation: GestureRecongnitionInformation) {
        if ((gestureInformation.isHandsUp)) {
            let handsup = gestureInformation.isHandsUp
            self.delegate?.handsupDataChanged(handsUp: handsup)
        }
        
        self.delegate?.didUpdateBodyTrackingData(bodyTrackingData: bodyTrackingData)
    }
    
    
    
    func handsUpDataChanged(handsUp : Bool) {
        // will show hands up here
//        self.delegate?.handsupDataChanged(handsUp: handsUp)
    }
    
    func shoulderBrushedDataChanged(brushedLeftShoulder : Bool, brushedRightShoulder : Bool) {
        self.delegate?.brushedShoulderDataChanged(brushedLeftShoulder: brushedLeftShoulder, brushedRightShoulder: brushedRightShoulder)
    }
    
    func didUpdatePixelBuffer(pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription) {
        self.previewVideo?.pixelBuffer = pixelBuffer
        self.BackgroundVideo?.pixelBuffer = pixelBuffer
        self.BackgroundVideo?.formatDescription = formatDescription
    }
    
    func didUpdatePoseEstimationData(poseEstimationData: Any, bodyTrackingData: BodyTrackingData, points: [PredictedPoint?], gestureInformation: GestureRecongnitionInformation) {
        
    }
    
    func didUpdateFaceDetectionData(faceDetectionData: FaceDetectionData) {
        self.delegate?.didUpdateFaceTrackingData(faceTrackingData: faceDetectionData)
    }
    
    func didUpdateSemanticSegmentationData(semanticSegmentationData: SemanticSegmentationInformation) {
//        guard let image = semanticSegmentationData.overlayImage.first else { return }
//        self.BackgroundVideo?.pixelBuffer = semanticSegmentationData.pixelBuffer
    }
    
    
}

extension GameViewController {
    // - REPLAY KIT
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

