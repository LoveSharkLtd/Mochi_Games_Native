//
//  gameScene.swift
//  Mochi Games
//
//  Created by Sam Weekes on 4/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, GameViewControllerDelegate {
    func didUpdateFaceTrackingData(faceTrackingData: FaceDetectionData) {
        let W = (self.scene?.size.width)!
        let H = (self.scene?.size.height)!
        let w = faceTrackingData.width * W
        let h = faceTrackingData.height * H
        let x = faceTrackingData.x * W - 0.5 * W + 0.5 * w
        let y = -(faceTrackingData.y - 0.5) * H - 0.5 * h
        
        let action = SKAction.move(to: CGPoint(x : x, y : y), duration: 0.05)
        action.timingMode = .easeIn
        self.faceNode?.run(action)
    }
    
    func didUpdateBodyTrackingData(bodyTrackingData: BodyTrackingData) {
        
//        print("!! - - wrist R = \(bodyTrackingData.wrist.right) \(bodyTrackingData.wrist.confidenceRight)")
        let W = (self.scene?.size.width)!
        let H = (self.scene?.size.height)!
        let w = bodyTrackingData.wrist.right?.x ?? 0.0 * W
        let h = bodyTrackingData.wrist.right?.y ?? 0.0 * H
        let x = (bodyTrackingData.wrist.right?.x ?? 0.0) * W // + 0.5 * w
        let y = CGFloat(0.0) // -(bodyTrackingData.wrist.right?.y - 0.5) * H - 0.5 * h
        
        self.wristNode?.position = CGPoint(x: x, y: y)
        return
//
////        print("!! - wrist = \(bodyTrackingData.wrist.right)")
//
//        let n = Float.minimum(bodyTrackingData.wrist.confidenceRight, 1.0)
//        let oldPos = self.wristNode?.position
//        let newPos = pixelPositionToSpriteKitPosition(bodyTrackingData.wrist.right)
//
//        print("!! -- conf = \(bodyTrackingData.wrist.confidenceRight)")
//
//        self.wristNode?.position = pixelPositionToSpriteKitPosition(bodyTrackingData.wrist.right)
//        return
//
////        let x = CGFloat(n) * (newPos.x - oldPos!.x) + oldPos!.x
////        let y = CGFloat(n) * (newPos.y - oldPos!.y) + oldPos!.y
////
////        self.wristNode?.position = CGPoint(x: x, y: y)
    }
    
    func pixelPositionToSpriteKitPosition(_ pixelPosition : [Float]) -> CGPoint {
        guard let scaler = viewController?.getImageScaler() else {
            return CGPoint.zero
        }
        
        let size = scene?.size
        let x = size!.width * scaler.width * (CGFloat(pixelPosition[0]) - 0.5)
        let y = -size!.height * scaler.height * (CGFloat(pixelPosition[1]) - 0.5)
        let position : CGPoint = CGPoint(x: x, y: y)
        
        return position
    }
    
    var wristNode : SKNode?
    var faceNode : SKNode?
    var handsupNode : SKNode?
    var brushLNode : SKNode?
    var brushRNode : SKNode?
    
    var isAnimating : Bool = false
    
    public var viewController : GameViewController? {
        didSet {
            viewController?.delegate = self
        }
    }
    
    
    func handsupDataChanged(handsUp: Bool) {
        // /*
        
        print("!! - hands up \(handsUp) - \(isAnimating)")
        
        if !handsUp || isAnimating { return }
        
        self.isAnimating = true
        
        let fadein = SKAction.fadeIn(withDuration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        
        let sIn : CGFloat = 1.25
        let sOut : CGFloat = 1.0
        
        let scaleIn = SKAction.scale(to: sIn, duration: 0.15)
        scaleIn.timingMode = .easeIn
        
        let scaleOut = SKAction.scale(to: sOut, duration: 0.15)
        scaleIn.timingMode = .easeOut
        
        let delay = SKAction.wait(forDuration: 2.0)
        
        let hider = self.faceNode?.childNode(withName: "hider")
        hider?.alpha = 0
        
        hider?.run(SKAction.sequence([fadein, delay, fadeOut]), completion: {
            () -> Void in
            self.isAnimating = false
        })
        
        // */
    }
    
    func brushedShoulderDataChanged(brushedLeftShoulder: Bool, brushedRightShoulder: Bool) {
        /*
        let fadein = SKAction.fadeIn(withDuration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        
        let sIn : CGFloat = 1.25
        let sOut : CGFloat = 1.0
        
        let scaleIn = SKAction.scale(to: sIn, duration: 0.15)
        scaleIn.timingMode = .easeIn
        
        let scaleOut = SKAction.scale(to: sOut, duration: 0.15)
        scaleIn.timingMode = .easeOut
        
        brushLNode?.run(brushedLeftShoulder ? fadein : fadeOut)
        brushLNode?.run(brushedLeftShoulder ? scaleIn : scaleOut)
        
        self.handsupNode?.run(fadeOut)
        self.handsupNode?.run(scaleOut)
        
        brushRNode?.run(brushedRightShoulder ? fadein : fadeOut)
        brushRNode?.run(brushedRightShoulder ? scaleIn : scaleOut)
        // */
    }
    
    override func didMove(to view: SKView) {
        
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func sceneDidLoad() {
        print("!! - scene loaded")
        wristNode = self.childNode(withName: "wristNode")
        faceNode = self.childNode(withName: "faceParent")
        
        handsupNode = self.childNode(withName: "handsup")
        
        
        var emitterL = handsupNode?.childNode(withName: "L")
        var emitterR = handsupNode?.childNode(withName: "R")
        
        emitterR?.addChild(getHUSparkles()!)
        emitterL?.addChild(getHUSparkles()!)
        
        handsupNode?.alpha = 0.0
        
        brushLNode = self.childNode(withName: "brushL")
        
        emitterL = brushLNode?.childNode(withName: "L")
        
        emitterL?.addChild(getBLSparkles()!)
        
        brushLNode?.alpha = 0.0
        
        
        
        brushRNode = self.childNode(withName: "brushR")
        
        emitterL = brushRNode?.childNode(withName: "L")
        emitterR = brushRNode?.childNode(withName: "R")
        
        emitterL?.addChild(getBRSparkles()!)
        emitterR?.addChild(getBRSparkles()!)
        
        brushRNode?.alpha = 0.0
    }
    
    func getHUSparkles() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "particle.sks")
    }
    
    func getBLSparkles() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "BLparticle.sks")
    }
    
    func getBRSparkles() -> SKEmitterNode? {
        return SKEmitterNode(fileNamed: "BRparticles.sks")
    }
    
    override func update(_ currentTime: TimeInterval) {
    }
}
