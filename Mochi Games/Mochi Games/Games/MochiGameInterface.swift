//
//  MochiGameInterface.swift
//  Mochi Games
//
//  Created by Sam Weekes on 5/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import ReplayKit
import GameplayKit

class MochiGameInterface {
    
    public var view : UIView? {
        return _view
    }
    
    public var nonRecordView : UIView? {
        return hiddenView
    }
    
    public var nonRecordWindow : UIWindow? {
        return hiddenWindow
    }
    
    
    private var hiddenView : UIView?
    private var hiddenWindow : UIWindow?

    private var _view : UIView?
    private var cameraFeed : MTLCameraView?
    private var skview : SKView?
    private var scene : SKScene?
    
    var gameplayDelegate : MochiGameplayDelegate?
    var interfaceDelegate : MochiGameInterfaceDelegate?
    
    let gameSceneString = "DanceScene" // !! - this needs to be the same as in the scene
    let faceTrackerSceneString = "FaceTracking" // !! - this will contain the face tracking parent
    let bodyTrackingSceneString = "BodyTracking" // !! - this will contain the face tracking parent
    
    
    init() {
        updateScreenScales()
        let frame = CGRect(x: 0.0, y: 0.0, width: sW, height: sH)
        
        _view = UIView(frame: frame)
        
        cameraFeed = MTLCameraView(frame: frame, device: MTLCreateSystemDefaultDevice())
        _view?.addSubview(cameraFeed!)
        
        // - spritekit view
        skview = SKView(frame: frame)
        skview?.allowsTransparency = true
        skview?.ignoresSiblingOrder = true
        _view?.addSubview(self.skview!)
        
        let cv = CVInterface()
        cv.cvInterfaceDelegate = self
        cv.loadCameraAndRun() // only wanna load camera here !
        
        setUpNonRecordRoot()
        
    }
    
    func setUpNonRecordRoot() {
        let frame = CGRect(x: 0.0, y: 0.0, width: sW, height: sH)
        hiddenWindow = UIWindow(frame: frame)
        hiddenWindow?.rootViewController = nonRecordingViewController()
        
        hiddenView = UIView(frame: frame)
        hiddenWindow?.rootViewController?.view.addSubview(hiddenView!)
    }
    
    public func setUpGame() {
        self.scene = SKScene(fileNamed: gameSceneString)
        self.scene?.scaleMode = .aspectFill
        self.skview?.presentScene(scene)
        
        // here we need to add preview video
        // set up beat scoring -
        // initialise the cosmetics
        // set up CV
    }
    
    public func Destroy() {
        
    }
    
    func setUpFaceTracking() -> SKNode? {
        // !! - set up face tracking on CV Interface
        let faceTrackingScene = SKScene(fileNamed: faceTrackerSceneString)
        return faceTrackingScene?.childNode(withName: "FaceNode")
    }
    
    func setUpBodyTracking() -> SKBodyTrackingData? {
        // !! - set up body tracking on CV Interface
        guard let bodyTrackingScene = SKScene(fileNamed: bodyTrackingSceneString),
            let parent = bodyTrackingScene.childNode(withName: "BodyTrackParent"),
        let top = bodyTrackingScene.childNode(withName: "Top"),
        let neck = bodyTrackingScene.childNode(withName: "Neck"),
        let shoulderL = bodyTrackingScene.childNode(withName: "ShoulderLeft"),
        let shoulderR = bodyTrackingScene.childNode(withName: "ShoulderRight"),
        let elbowL = bodyTrackingScene.childNode(withName: "ElbowLeft"),
        let elbowR = bodyTrackingScene.childNode(withName: "ElbowRight"),
        let wristL = bodyTrackingScene.childNode(withName: "WristLeft"),
        let wristR = bodyTrackingScene.childNode(withName: "WristRight"),
        let hipL = bodyTrackingScene.childNode(withName: "HipLeft"),
        let hipR = bodyTrackingScene.childNode(withName: "HipRight"),
        let kneeL = bodyTrackingScene.childNode(withName: "KneeLeft"),
        let kneeR = bodyTrackingScene.childNode(withName: "KneeRight"),
        let ankleL = bodyTrackingScene.childNode(withName: "AnkleLeft"),
        let ankleR = bodyTrackingScene.childNode(withName: "AnkleRight") else { return nil }
        
        return SKBodyTrackingData(parent: parent, top: top, neck: neck, shoulders: SKBodyTrackingPositions(left: shoulderL, right: shoulderR), elbows: SKBodyTrackingPositions(left: elbowL, right: elbowR), wrists: SKBodyTrackingPositions(left: wristL, right: wristR), hips: SKBodyTrackingPositions(left: hipL, right: hipR), knees: SKBodyTrackingPositions(left: kneeL, right: kneeR), ankles: SKBodyTrackingPositions(left: ankleL, right: ankleR))
    }
    
}

protocol MochiGameplayDelegate {
    // - body tracking data -
    // - face tracking data
    // - gesture recog data
    // -
}

protocol MochiGameInterfaceDelegate {
    // - end of game
    // - end of level
    // -
}

extension MochiGameInterface: CVInterfaceDelegate {
    func didUpdatePixelBuffer(pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription) {
        self.cameraFeed?.pixelBuffer = pixelBuffer
        self.cameraFeed?.formatDescription = formatDescription
    }
    
    func didUpdateGestureRecognitionData(gestureRecognitionData: Any) {
//        <#code#>
    }
    
    func didUpdatePoseEstimationData(poseEstimationData: Any, bodyTrackingData: BodyTrackingData, points: [PredictedPoint?], gestureInformation: GestureRecongnitionInformation) {
//        <#code#>
    }
    
    func didUpdateFaceDetectionData(faceDetectionData: FaceDetectionData) {
//        <#code#>
    }
    
    func didUpdateSemanticSegmentationData(semanticSegmentationData: SemanticSegmentationInformation) {
//        <#code#>
    }
    
    
}



class nonRecordingViewController : UIViewController {
    override var prefersStatusBarHidden : Bool { return true }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}





struct SKBodyTrackingData {
    var parent : SKNode
    var top : SKNode
    var neck : SKNode
    var shoulders : SKBodyTrackingPositions
    var elbows : SKBodyTrackingPositions
    var wrists : SKBodyTrackingPositions
    var hips : SKBodyTrackingPositions
    var knees : SKBodyTrackingPositions
    var ankles : SKBodyTrackingPositions
}

struct SKBodyTrackingPositions {
    var left : SKNode
    var right : SKNode
}




class Recorder : RPScreenRecorder {
    // - We need to make a recorder here
}

class CosmeticController {
    
}
