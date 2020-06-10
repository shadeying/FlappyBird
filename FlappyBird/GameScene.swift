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
    var scrollLayer: SKNode!
    var pipeLayer: SKNode!
    var sinceTouch : CFTimeInterval = 0 // keep track of touch time to turn the flappybird
    var spawnTimer: CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    let scrollSpeed: CGFloat = 160
    
    override func didMove(to view: SKView) {
        /* Set up your scene here */
        
        /* Recursive node search for 'flappybird' (child of referenced node) */
        flappybird = self.childNode(withName: "//flappybird") as? SKSpriteNode
        
        /* Set reference to scroll layer node */
        scrollLayer = self.childNode(withName: "scrollLayer")
        
        /* Set reference to pipe layer node */
        pipeLayer = self.childNode(withName: "pipeLayer")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       /* Called when a touch begins */
        
        /* Apply vertical impulse */
        flappybird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
        
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
        let _ = flappybird.zRotation.clamp(v1: CGFloat(-20).degreesToRadians(),CGFloat(30).degreesToRadians())
        let _ = flappybird.physicsBody?.angularVelocity.clamp(v1: -2, 2)

        /* Update last touch timer */
        sinceTouch += fixedDelta
        scrollWorld()
        movePipes()
        spawnTimer += fixedDelta
    }
    
    func scrollWorld() {
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes */
        for Ground in scrollLayer.children as! [SKSpriteNode] {
            /* Get Ground node position, convert node position to scene space */
            let groundPosition = scrollLayer.convert(Ground.position, to: self)
            
            /* Check if ground sprite has left the scene */
            if(groundPosition.x <= -Ground.size.width / 2) {
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPoint(x: (self.size.width / 2) + Ground.size.width, y: groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                Ground.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    func movePipes() {
        /* Move pipes here */
        pipeLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through pipe layer nodes */
        for pipe in pipeLayer.children as! [SKReferenceNode] {
             /* Get pipe node position, convert node position to scene space */
            let pipePosition = pipeLayer.convert(pipe.position, to: self)
            
            /* Check if pipe has left the scene */
            if(pipePosition.x <= 0) {
                /* Remove pipe node from pipe layer */
                pipe.removeFromParent()
            }
        }
        
        /* Add new pipe? */
        if(spawnTimer >= 1.5) {
            /* Create a new pipe reference object using our pipe resource */
            let resourcePath = Bundle.main.path(forResource: "Pipe", ofType: "sks")
            let newPipe = SKReferenceNode(url: NSURL(fileURLWithPath: resourcePath!) as URL)
            pipeLayer.addChild(newPipe)
            
            /* Generate new pipe position, start just outside screen and with a random y value */
            let randomPosition = CGPoint(x: 352, y: CGFloat.random(in: 234...382))
            
            /* Convert new node position back to pipe layer space */
            newPipe.position = self.convert(randomPosition, to: pipeLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
    }
}
