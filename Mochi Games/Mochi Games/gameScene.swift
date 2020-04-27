//
//  gameScene.swift
//  Mochi Games
//
//  Created by Sam Weekes on 4/27/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var skimagenode : SKSpriteNode?

    override init() {
        super.init(size: CGSize(width: sW, height: sH))
        let h = sH * 0.5
        let w = h * sW / sH
        skimagenode = SKSpriteNode()
        skimagenode?.size = CGSize(width: w, height: w)
        skimagenode?.position = CGPoint(x: sW * 0.5, y: sH * 0.75)
        skimagenode?.color = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        
        self.addChild(skimagenode!)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    
    override func update(_ currentTime: TimeInterval) {
        self.skimagenode?.zRotation += 0.01
    }
}
