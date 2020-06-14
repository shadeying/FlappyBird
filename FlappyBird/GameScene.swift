//
//  GameScene.swift
//  FlappyBird
//
//  Created by Shade Wong on 2020-06-09.
//  Copyright © 2020 Shade Wong. All rights reserved.
//

import SpriteKit

enum GameSceneState {
    case Active, GameOver, Wait
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var flappybird: SKSpriteNode!
    var scrollLayer: SKNode!
    var pipeLayer: SKNode!
    var sinceTouch : CFTimeInterval = 0 // keep track of touch time to turn the flappybird
    var spawnTimer: CFTimeInterval = 0
    var gameState: GameSceneState = .Active // game management
    var scoreLabel: SKLabelNode!
    var points = 0
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    let scrollSpeed: CGFloat = 160
    
    override func didMove(to view: SKView) {
        /* Set up scene */
        
        /* Recursive node search for 'flappybird' (child of referenced node) */
        flappybird = self.childNode(withName: "//flappybird") as? SKSpriteNode
        
        /* Set reference to scroll layer node */
        scrollLayer = self.childNode(withName: "scrollLayer")
        
        /* Set reference to pipe layer node */
        pipeLayer = self.childNode(withName: "pipeLayer")
        
        scoreLabel = self.childNode(withName: "scoreLabel") as? SKLabelNode
        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
        
        /* Reset Score label */
        scoreLabel.text = String(points)
        
    }
    
    func restartGame() {
        /* Grab reference to SpriteKit view */
        let skView = self.view! as SKView
        
        /* Load Game scene */
        let scene = GameScene(fileNamed: "GameScene")! as GameScene
        
        /* Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        /* Restart game scene */
        skView.presentScene(scene)
        gameState = .Wait
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       /* Called when a touch begins */
        if gameState != .Active {
            restartGame()
        }
        
        if gameState == .GameOver {
            return
        }
        
        /* Reset velocity, helps improve response against cumulative falling velocity */
        flappybird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
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
        /* Skip game update if game no longer active */
        if gameState != .Active {
            return
        }
        
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
        let _ = flappybird.zRotation.clamp(v1: CGFloat(-20).degreesToRadians(),CGFloat(20).degreesToRadians())
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
            
            /* Reset spawn timer */
            spawnTimer = 0
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        /* Called only when the game is running */
        if gameState != .Active {
            return
        }
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Check if the bird has passed through the 'goal' */
        if nodeA.name == "goal" || nodeB.name == "goal" {
            /* Increment points */
            points += 1
            /* Update score label */
            scoreLabel.text = String(points)
            return
        }
        
        /* Game over if bird touches anything */
        /* Change game state to game over */
        gameState = .GameOver
        
        /* Stop any new angular velocity being applied */
        flappybird.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        flappybird.physicsBody?.angularVelocity = 0
        
        /* Stop flapping animation */
        flappybird.removeAllActions()
        
        /* Create flappybird death action */
        let flappybirdDeath = SKAction.run({
            /* Put bird face down in the dirt */
            self.flappybird.zRotation = CGFloat(80).degreesToRadians()
             /* Stop bird from colliding with anything else */
            self.flappybird.physicsBody?.collisionBitMask = 0
        })
        
        /* Run death action */
        flappybird.run(flappybirdDeath)
        
        /* Load the shake action resource */
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /* Loop through all nodes  */
        for node in self.children {
            /* Apply effect each ground node */
            node.run(shakeScene)
        }
    }
    
}
