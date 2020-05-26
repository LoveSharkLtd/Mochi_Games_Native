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
        let action = SKAction.move(to: pixelPositionToSKPosition(faceTrackingData), duration: 0.05)
        action.timingMode = .easeIn
        self.faceNode?.run(action)
    }
    
    func didUpdateBodyTrackingData(bodyTrackingData: BodyTrackingData) {
        guard let top = bodyTrackingData.top.middle else {
            return
        }
        guard let topConfidence = bodyTrackingData.top.confidenceMiddle else {
            return
        }
        let conf = 1.0 / topConfidence
        let action = SKAction.move(to: pixelPositionToSKPosition(top), duration: 0.05 * (1.0 * conf))
        action.timingMode = .easeIn
        
        self.wristNode?.run(action)
        
//        self.wristNode?.position = CGPoint(x: x, y: y)
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


extension GameScene {
    // - Utilities for converting from CV Data to SpriteKit
    // - ASSUMPTIONS :
    // -        1 ) CV Data Origins are at the top left of the screen (-0.5, 0.5) in SK co-ords
    // -        2 ) CV Data is aligned to a portrait device (ie X-Axis in the data is X-Axis in the SK Scene)
    
    // - Generic Conversion
    func pixelPositionToSKPosition(_ position : CGPoint) -> CGPoint {
        let W = self.size.width
        let H = self.size.height
        
        let x = (position.x - 0.5) * W
        let y = (0.5 - position.y) * H
        
        return CGPoint(x: x, y: y)
    }
    
    // - Face Tracking variant : need to account for the x / y values of data are the T-L position of the face.
    func pixelPositionToSKPosition(_ faceData : FaceDetectionData) -> CGPoint {
        let W = self.size.width
        let H = self.size.height
        
        let w = faceData.width * W
        let h = faceData.height * H
        
        let x = (faceData.x - 0.5) * W + 0.5 * w
        let y = (0.5 - faceData.y) * H - 0.5 * h
        
        return CGPoint(x: x, y: y)
    }
    
}
