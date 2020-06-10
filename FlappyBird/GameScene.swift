//
//  GameScene.swift
//  FlappyBird
//
//  Created by Shade Wong on 2020-06-09.
//  Copyright © 2020 Shade Wong. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var flappybird: SKSpriteNode!
    var sinceTouch : CFTimeInterval = 0 // keep track of touch time to turn the flappybird
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    
    override func didMove(to view: SKView) {
        /* Set up your scene here */
        
        /* Recursive node search for 'flappybird' (child of referenced node) */
        flappybird = self.childNode(withName: "//flappybird") as? SKSpriteNode
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       /* Called when a touch begins */
        
        /* Apply vertical impulse */
        flappybird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))
        
        /* Apply subtle rotation */
        flappybird.physicsBody?.applyAngularImpulse(1)

        /* Reset touch timer */
        sinceTouch = 0
        
        /* Play SFX */
        let flapSFX = SKAction.playSoundFileNamed("sfx_flap", waitForCompletion: false)
        self.run(flapSFX)
    }

    override func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        /* Grab current velocity */
        let velocityY = flappybird.physicsBody?.velocity.dy ?? 0

        /* Check and cap vertical velocity */
        if velocityY > 400 {
          flappybird.physicsBody?.velocity.dy = 400
        }
        
        /* Apply falling rotation */
        if sinceTouch > 0.1 {
            let impulse = -20000 * fixedDelta
            flappybird.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }

        /* Clamp rotation */
        let _ = flappybird.zRotation.clamp(v1: CGFloat(-20).degreesToRadians(),CGFloat(40).degreesToRadians())
        let _ = flappybird.physicsBody?.angularVelocity.clamp(v1: -2, 2)

        /* Update last touch timer */
        sinceTouch += fixedDelta
    }
}
