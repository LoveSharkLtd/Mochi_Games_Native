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
    
    
    func getImageScaler() -> CGSize? {
        return self.BackgroundVideo?.scaler
    }
    
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
        
        cvInterface.load()
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
        
        createMLButtonActions() // - remove when ml is in
        
        nonRecordWindow.rootViewController?.view.addSubview(previewVideo!)
        
        nonRecordWindow.makeKeyAndVisible()
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        nonRecordWindow.rootViewController?.view.addGestureRecognizer(tapGesture)
    }
    
    func createMLButtonActions() {
        
        let h_ = sHR * 50 / 667
        let w_ = _deviceType == .iPad ? sHR * 356 / 667 : sW - sHR * 20 / 667
        let g = sHR * 10 / 667
        
        let btnW = (w_ - 2.0 * g) / 3.0
        for i in 0..<3 {
            let x = g + CGFloat(i) * (btnW + g)
            let y = sH - h_ - g - g - 1.5 * h_ - g
            var str = "hands up"
            if i == 1 { str = "brush L" }
            if i == 2 { str = "brush R" }
            
            let btn = createButton(width: btnW, height: h_, title: str, textSize: nil)
            btn.frame.origin = CGPoint(x: x, y: y)

            btn.addTarget(self, action: #selector(ButtonDown(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(ButtonUp(_:)), for: .touchUpOutside)
            
            if i == 0 { btn.addTarget(self, action: #selector(handsUpBtnPressed(_:)), for: .touchUpInside) }
            if i == 1 { btn.addTarget(self, action: #selector(brushedLeftBtnPressed(_:)), for: .touchUpInside) }
            if i == 2 { btn.addTarget(self, action: #selector(brushedRightBtnPressed(_:)), for: .touchUpInside) }
            
            nonRecordWindow.rootViewController?.view.addSubview(btn)
            
        }
        
    }
    
    
    @objc func tapped(_ gesture: UITapGestureRecognizer) {
            // !! - use this until we can add these calls to the game
            self.BackgroundVideo?.toggleFiltering()
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

    
    // - just using this to test the gamescene stuff :D
    @objc func handsUpBtnPressed(_ sender : UIButton) {
        ButtonUp(sender)
        
        handsUpBool = !handsUpBool
        BRBool = false
        BLBool = false
        handsUpDataChanged(handsUp: handsUpBool)
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.handsUpDataChanged(handsUp: false)
//        }
    }
    
    @objc func brushedLeftBtnPressed(_ sender : UIButton) {
        ButtonUp(sender)
        
        BLBool = !BLBool
        BRBool = false
        handsUpBool = false
        shoulderBrushedDataChanged(brushedLeftShoulder: BLBool, brushedRightShoulder: BRBool)
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.shoulderBrushedDataChanged(brushedLeftShoulder: false, brushedRightShoulder: false)
//        }
    }
    @objc func brushedRightBtnPressed(_ sender : UIButton) {
        ButtonUp(sender)
        
        BRBool = !BRBool
        BLBool = false
        handsUpBool = false
        shoulderBrushedDataChanged(brushedLeftShoulder: BLBool, brushedRightShoulder: BRBool)
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.shoulderBrushedDataChanged(brushedLeftShoulder: false, brushedRightShoulder: false)
//        }
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



extension GameViewController: CVInterfaceDelegate {
    
    
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
    
    func didUpdateGestureRecognitionData(gestureRecognitionData: Any) {
//        print("!! Gesture Recognition \(gestureRecognitionData)")
    }
    
    func didUpdatePoseEstimationData(poseEstimationData: Any, bodyTrackingData: BodyTrackingData, points: [PredictedPoint?], gestureInformation: [String: Bool?]) {
                if ((gestureInformation["isHandsUp"]!!)) {
                    let handsup = gestureInformation["isHandsUp"]!!
                    self.delegate?.handsupDataChanged(handsUp: handsup)
                }
        
        self.delegate?.didUpdateBodyTrackingData(bodyTrackingData: bodyTrackingData)
        
//        print("__ __ gesture recog = \(gestureInformation)")
        
        
        return
//
//        // Action if the shoulder is brushed
//        if ((gestureInformation["isShoulderBrush"]!!)) {
//            let brushedShoulder = gestureInformation["isShoulderBrush"]!!
//            shoulderBrushedDataChanged(brushedLeftShoulder: brushedShoulder, brushedRightShoulder: false)
//        }
////
//
//
//        // Remove points that have been added previously
//        for v in view.subviews{
//           if v is UILabel{
//              v.removeFromSuperview()
//           }
//        }
//
//        // Define label color, size and width
//        let pointSize = CGSize(width: 100, height: 20)
//        let color:UIColor = .red
//
//        // Joint Labels for on screen text
//        let pointLabels: [String] = [
//            "top",          //0
//            "neck",         //1
//            "R shoulder",   //2
//            "R elbow",      //3
//            "R wrist",      //4
//            "L shoulder",   //5
//            "L elbow",      //6
//            "L wrist",      //7
//            "R hip",        //8
//            "R knee",       //9
//            "R ankle",      //10
//            "L hip",        //11
//            "L knee",       //12
//            "L ankle",      //13
//        ]
//
//        // Loop through the points and place labels based on their positions
//        for (index, point) in points.enumerated() {
//
//            let x = CGFloat((point?.maxPoint.x ?? 0) * UIScreen.main.bounds.width)
//            let y = CGFloat((point?.maxPoint.y ?? 0) * UIScreen.main.bounds.height)
//
//            // Create a label view for each point
//            let pointView = UILabel(frame: CGRect(x: 0, y: 0, width: pointSize.width, height: pointSize.height))
//            pointView.backgroundColor = color
//            pointView.clipsToBounds = false
//            pointView.layer.cornerRadius = 5
//            pointView.layer.borderColor = UIColor.black.cgColor
//            pointView.layer.borderWidth = 1.4
//            pointView.text = pointLabels[index]
//
//            pointView.center = CGPoint(x: x, y:y)
//
//            // Add points to view
//            self.view.addSubview(pointView)
//
//        }
    }
    
    func TBDpixelPositionToSpriteKitPosition(_ pixelPosition : [Float]) -> CGPoint {
        guard let scaler = self.getImageScaler() else {
            return CGPoint.zero
        }
        
        let size = CGSize(width: sW, height: sH)
        let x = size.width * scaler.width * (CGFloat(pixelPosition[0]))
        let y = size.height * scaler.height * (CGFloat(pixelPosition[1]))
        let position : CGPoint = CGPoint(x: x, y: y)
        
        return position
    }
    
    
    
    func didUpdateFaceDetectionData(faceDetectionData: FaceDetectionData) {
        self.delegate?.didUpdateFaceTrackingData(faceTrackingData: faceDetectionData)
//        let rectHeight = faceDetectionData.width * sH
//        let rectWidth = faceDetectionData.height * sW
//        let yPos = faceDetectionData.origin.x * sH
//        let xPos = faceDetectionData.origin.y * sW
//
//        DispatchQueue.main.async {
//            // Remove points that have been added previously
////            for v in (self.boundingBoxViewParent?.subviews)! {
////                  v.removeFromSuperview()
////            }
//
//            let rectFrame: CGRect = CGRect(x:xPos, y:yPos, width:rectWidth, height:rectHeight)
//            if self.boundingBox == nil {
//
//                self.boundingBox = UIView(frame: rectFrame)
//                self.boundingBox?.backgroundColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1).withAlphaComponent(0.7)
//                self.boundingBoxViewParent?.addSubview(self.boundingBox!)
//
//            } else {
//                self.boundingBox?.frame = rectFrame
//            }
////            let boundingBoxView = UIView(frame: rectFrame)
//
//            // Add points to view
//        }
    }
    
    func didUpdateSemanticSegmentationData(semanticSegmentationData: SemanticSegmentationInformation) {
//        guard let image = semanticSegmentationData.overlayImage.first else { return }
//        self.BackgroundVideo?.pixelBuffer = semanticSegmentationData.pixelBuffer
    }
    
    
}


struct FaceDetectionData {
    var x : CGFloat
    var y : CGFloat
    var height : CGFloat
    var width : CGFloat
}
