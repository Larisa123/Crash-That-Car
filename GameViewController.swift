//
//  GameViewController.swift
//  CrashThatCar
//
//  Created by Lara Carli on 9/30/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//

struct PhysicsCategory {
	static let none: Int = 0
	static let floor: Int = -1
	static let car: Int = 2
	static let speedUpObstacle: Int = 4
	static let barrier: Int = 8
	static let obstacle: Int = 16
	static let finishLine: Int = 32
	static let borderLine: Int = 64
	static let middleLine: Int = 128
}

struct Obstacle {
	static let normal: String = "normal"
	static let inBarrier: String = "inBarrier"
	static let beingShot: String = "beingShot"
	static let shot: String = "shot"
	static let readyToBeExploded: String = "readyToBeExploded"
}

let pi = Float(M_PI)

enum GameState { //not finite
	case preparingTheScene
	case tapToPlay
	case countDown
	case play
	case gameOver
}

import UIKit
import QuartzCore
import SceneKit
import SpriteKit
import ModelIO
import SceneKit.ModelIO


class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
	var scnView: SCNView!
	var deviceSize: CGSize!
	var raceScene: SCNScene?
	var gameOverScene: GameOverScene!
	
	
	//Cars
	var car1Node: SCNNode?
	var car2Node: SCNNode?
	var player1StartingPosition: SCNVector3!
	var player2StartingPosition: SCNVector3!
	let carVelocityMagnitude = 3.0
	
	var barrier1: SCNNode!
	var barrier2: SCNNode!
	var barrier2StartingPosition: SCNVector3!
	var barrier1StartingPosition: SCNVector3!
	
	var smokeEmitterArray: [SCNNode] = []
	
	//Obstacle
	var obstacleArray: [SCNNode] = []
	let obstacleVelocity: Float = 7.0
	var readyToShoot: Bool = false
	var obstacleScene: SCNScene!
	var obstacleNode: SCNNode!
	var speedUpObstacleScene: SCNScene!
	var speedUpObstacleNode: SCNNode!
	
	var speedUpObstacleArray: [SCNNode] = []
	
	let obstacleParticleSystem = SCNParticleSystem(named: "obstacleParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
	let obstacleExplodeParticleSystem = SCNParticleSystem(named: "obstacleExplodeParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
	let obstacleExplodeBigParticleSystem = SCNParticleSystem(named: "obstacleExplodeBigParticleSystem.scnp", inDirectory: "art.scnassets/Particles")!
	let readyToExplodeParticleSystem = SCNParticleSystem(named: "readyToExplode", inDirectory: "art.scnassets/Particles")!
	let carSmokeParticleSystem = SCNParticleSystem(named: "carSmoke.scnp", inDirectory: "art.scnassets/Particles")!
	let speedUpObstacleParticleSystem = SCNParticleSystem(named: "speedUp.scnp", inDirectory: "art.scnassets/Particles")!
	let speedUpObstacleExplodeParticleSystem = SCNParticleSystem(named: "speedUpObstacleExplode", inDirectory: "art.scnassets/Particles")
	
	//Camera
	var mainCamera: SCNNode?
	var sideCamera: SCNNode?
	
	//Playground and game
	let playgroundZ: Float = 20
	var lastTouchedLocation = CGPoint.zero
	
	var gameState: GameState = .preparingTheScene
	var tutorialFinished: Bool = false
	var sounds: [String:SCNAudioSource] = [:]
	

    override func viewDidLoad() {
        super.viewDidLoad()
		deviceSize = UIScreen.main.bounds.size
		gameOverScene = GameOverScene(gameViewController: self)
		
		setupView()
		setupScene()
		setupCars()
		setupCarBarriers()
		setupLines()
		setupCameras()
		setupSounds()
		
		prepareTheScene()
		setupObstacles()
	}
	
	//Setups:
	
	func setupView() {
		scnView = self.view as! SCNView!
		scnView.delegate = self
		//scnView.debugOptions = SCNDebugOptions.showPhysicsShapes
	}
	
	func setupScene() {
		raceScene = SCNScene(named: "art.scnassets/Scenes/raceScene.scn")
		scnView.scene = raceScene
		scnView.overlaySKScene = gameOverScene
		raceScene?.physicsWorld.contactDelegate = self
	}
	
	func setupCars() {
		car1Node = raceScene?.rootNode.childNode(withName: "player1Car reference", recursively: true)
		car2Node = raceScene?.rootNode.childNode(withName: "player2Car reference", recursively: true)
		
		for car in [car1Node, car2Node] {
			car?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
			car?.physicsBody?.isAffectedByGravity = false
			car?.physicsBody?.categoryBitMask = PhysicsCategory.car
			car?.physicsBody?.collisionBitMask = PhysicsCategory.floor | PhysicsCategory.borderLine | PhysicsCategory.middleLine
			car?.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.finishLine | PhysicsCategory.speedUpObstacle
			car?.physicsBody?.damping = 0
			car?.physicsBody?.angularDamping = 1
		}
		
		raceScene?.rootNode.enumerateChildNodes { node, stop in 
			if node.name == "smokeEmitter" { smokeEmitterArray.append(node) }
		}
		
		player1StartingPosition = car1Node?.presentation.position
		player2StartingPosition = car2Node?.presentation.position
		
	}
	
	func setupCarBarriers() {
		barrier1 = raceScene?.rootNode.childNode(withName: "car1Barrier reference", recursively: true)
		barrier2 = raceScene?.rootNode.childNode(withName: "car2Barrier reference", recursively: true)
		
		for barrier in [barrier1, barrier2] {
			barrier?.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
			barrier?.physicsBody?.categoryBitMask = PhysicsCategory.barrier
			barrier?.physicsBody?.collisionBitMask = PhysicsCategory.none
			barrier?.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
		}
		
		barrier1StartingPosition = barrier1.position
		barrier2StartingPosition = barrier2.position
	}
	
	func setupLines() {
		let finishLine = raceScene?.rootNode.childNode(withName: "finishLine", recursively: true)
		finishLine?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
		finishLine?.physicsBody?.categoryBitMask = PhysicsCategory.finishLine
		finishLine?.physicsBody?.collisionBitMask = PhysicsCategory.none
		finishLine?.physicsBody?.contactTestBitMask = PhysicsCategory.car
		
		let borderLineLeft = raceScene?.rootNode.childNode(withName: "borderLineLeft", recursively: true)
		let borderLineRight = raceScene?.rootNode.childNode(withName: "borderLineRight", recursively: true)
		
		for borderLine in [borderLineLeft, borderLineRight] {
			borderLine?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
			borderLine?.physicsBody?.categoryBitMask = PhysicsCategory.borderLine
			borderLine?.physicsBody?.collisionBitMask = PhysicsCategory.car
			borderLine?.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
		}
		
		let middleLine = raceScene?.rootNode.childNode(withName: "middleLine", recursively: true)
		middleLine?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
		middleLine?.physicsBody?.categoryBitMask = PhysicsCategory.middleLine
		middleLine?.physicsBody?.collisionBitMask = PhysicsCategory.car
		middleLine?.physicsBody?.contactTestBitMask = PhysicsCategory.none
	}
	
	func setupCameras() {
		mainCamera = raceScene?.rootNode.childNode(withName: "mainCamera", recursively: true)
		scnView.pointOfView = mainCamera
		
		sideCamera = raceScene?.rootNode.childNode(withName: "sideCamera", recursively: true)
	}
	
	
	//Camera:
	
	func getTheCameraToShowTheScene() {
		scnView.pointOfView = sideCamera
	}
	
	//Game:
	
	func prepareTheScene() {
		gameState = .preparingTheScene
		getTheCameraToShowTheScene()
	}
	
	func startTheGame() {
		
		scnView.overlaySKScene = nil
		
		self.startTheCar()
		self.gameState = .play
	}
	
	func replayGame() {
		gameOverScene.hideSprites()
		
		stopTheCars()
		
		barrier1?.position = barrier1StartingPosition
		barrier2?.position = barrier2StartingPosition
		
		car1Node?.isHidden = false
		car2Node?.isHidden = false
		
		mainCamera?.position.x = 1
		addObstacles()
		prepareTheScene()
	}
	
	func gameOver(carWon: SCNNode, atFinishLine: Bool) {
		let carWonName: String!
		
		if atFinishLine {
			carWonName = carWon.presentation.position.z > 0 ? "first": "second"
			gameState = .gameOver
			stopTheCars()
		} else {
			let carThatGotHit = carWon.presentation.position.z > 0 ? "first": "second"
			carWonName = carThatGotHit == "first" ? "second" : "first"
		}
		
		scnView.overlaySKScene = gameOverScene
		gameOverScene.popSpritesOnGameOver(carWon: carWonName)
		removeAllObstacles()
	}
	
	
	//Obstacles:
	
	func setupObstacles() {
		obstacleScene = SCNScene(named: "art.scnassets/Scenes/obstacleNormal.scn")
		obstacleNode = obstacleScene?.rootNode.childNode(withName: "obstacle", recursively: true)
		
		speedUpObstacleScene = SCNScene(named: "art.scnassets/Scenes/speedUpObstacle.scn")
		speedUpObstacleNode = speedUpObstacleScene?.rootNode.childNode(withName: "speedUpObstacle", recursively: true)
		
		addObstacles()
		addSpeedUpObstacles()
	}
	
	func addObstacles() {
		var delayTime: Double = 0.5
		var speedUpObstacleCopy: SCNNode?
		
		for i in 0...7 {
			for sign: Float in [-1.0, 1.0] {
				let randomPosition = SCNVector3(x: Float(i) * 13.0, y: 1.0, z: sign * Float(arc4random_uniform(UInt32(Int(playgroundZ/2 - 2.0))) + 1))
				
				
				//normal obstacle:
				let obstacleCopy = obstacleNode?.copy() as? SCNNode
				obstacleCopy?.position = randomPosition
				obstacleCopy?.name = Obstacle.normal
				
				obstacleCopy?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
				
				obstacleCopy?.physicsBody?.isAffectedByGravity = false
				obstacleCopy?.eulerAngles = SCNVector3(x: 15.0 * Float(i), y: Float(10 - i), z: 5.0 * Float(i) * sign)
				obstacleCopy?.physicsBody?.angularVelocity = SCNVector4(x: 0.5, y: 0.3, z: 0.2, w: 1.0)
				obstacleCopy?.physicsBody?.angularDamping = 0
				obstacleCopy?.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
				obstacleCopy?.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
				obstacleCopy?.physicsBody?.contactTestBitMask = PhysicsCategory.car | PhysicsCategory.barrier | PhysicsCategory.borderLine
				
				obstacleArray.append(obstacleCopy!)
				
				//speedUp obstacle:
				if i % 2 == 0 {
					speedUpObstacleCopy = speedUpObstacleNode.copy() as? SCNNode
					speedUpObstacleCopy?.position = randomPosition
					speedUpObstacleCopy?.position.x += 5.0
					speedUpObstacleCopy?.position.z += 6.0
					speedUpObstacleCopy?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
					speedUpObstacleCopy?.physicsBody?.categoryBitMask = PhysicsCategory.speedUpObstacle
					speedUpObstacleCopy?.physicsBody?.collisionBitMask = PhysicsCategory.none
					speedUpObstacleCopy?.physicsBody?.collisionBitMask = PhysicsCategory.car
					speedUpObstacleArray.append(speedUpObstacleCopy!)
				} else { speedUpObstacleCopy = nil }
				
				DispatchQueue.main.asyncAfter(deadline: .now() + delayTime, execute: {
					self.raceScene!.rootNode.addChildNode(obstacleCopy!)
					if speedUpObstacleCopy != nil {print("addedObstacle"); self.raceScene?.rootNode.addChildNode(speedUpObstacleCopy!) }
					self.playSound(node: obstacleCopy, name: "pop")
				})
				delayTime += 0.4
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + delayTime + 0.5, execute: {
			self.gameOverScene.showTapToPlayLogo()
		})
	}
	
	func addSpeedUpObstacles() {
		let speedUpObstacle = raceScene?.rootNode.childNode(withName: "speedUpObstacle reference", recursively: true)
		speedUpObstacle?.addParticleSystem(speedUpObstacleParticleSystem)
	}
	
	func obstacleCollidedWithCar(car: SCNNode, obstacle: SCNNode) {
		explodeObstacleBig(obstacle: obstacle)
		gameState = .gameOver
		stopTheCars()
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
			self.gameOver(carWon: car, atFinishLine: false)
		})
	}
	
	func obstacleInBarrier(barrier: SCNNode, obstacle: SCNNode) {
		if obstacle.name == Obstacle.normal { //player can shot the obstacle at the other player
			obstacle.name = Obstacle.inBarrier
			obstacle.addParticleSystem(readyToExplodeParticleSystem)
		} else if obstacle.name == Obstacle.shot {
			//add an effect so the player can easily see when he can explode the obstacle that is trying to hit him
			
			obstacle.name = Obstacle.readyToBeExploded // player can explode the obstacle
		}
	}
	
	func shotTheObstacle(atVelocity velocity: SCNVector3) {
		for obstacle in obstacleArray { //to predolgo traja
			if obstacle.name == Obstacle.beingShot {
				obstacle.removeParticleSystem(readyToExplodeParticleSystem)
				obstacle.addParticleSystem(obstacleParticleSystem)
				obstacle.physicsBody?.applyForce(velocity, asImpulse: true)
				obstacle.name = Obstacle.shot
			}
		}
	}
	
	func explodeObstacle(obstacle: SCNNode, speedUpType: Bool) {
		let position = obstacle.presentation.position
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		
		let particleSystem = speedUpType ? speedUpObstacleExplodeParticleSystem : obstacleExplodeParticleSystem
		
		raceScene?.addParticleSystem(particleSystem!, transform: translationMatrix)
		obstacle.removeFromParentNode()
	}
	
	func explodeObstacleBig(obstacle: SCNNode) {
		let position = obstacle.presentation.position
		let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
		
		raceScene?.addParticleSystem(obstacleExplodeBigParticleSystem, transform: translationMatrix)
		playSound(node: car1Node, name: "explosion")
		obstacle.removeFromParentNode()
	}
	
	func removeAllObstacles() {
		playSound(node: mainCamera, name: "explosion")
		for obstacle in obstacleArray {
			explodeObstacle(obstacle: obstacle, speedUpType: false) //also removes it
		}
		
		for speedUpObstacle in speedUpObstacleArray {
			explodeObstacle(obstacle: speedUpObstacle, speedUpType: true)
		}
	}
	
	//Cars:
	
	func calculateVelocity(point1: CGPoint, point2: CGPoint) -> SCNVector3 {
		let deltaY = Float(point2.y - point1.y)
		let deltaX = Float(point2.x - point1.x)

		let magnitude = sqrt(deltaY*deltaY + deltaX*deltaX)
		let xComponent = deltaX / magnitude * obstacleVelocity
		let zComponent = deltaY / magnitude * obstacleVelocity

		return SCNVector3(xComponent, 0, zComponent)
	}
	
	func startTheCar() {
		
		let brrrm = SCNAction.run({_ in
			//play brrmm sound (ko se vgžuje avto)
		})
		
		let driveCars = SCNAction.run({_ in
			self.car1Node?.physicsBody?.velocity = SCNVector3(self.carVelocityMagnitude, 0, 0)
			self.car2Node?.physicsBody?.velocity = SCNVector3(self.carVelocityMagnitude, 0, 0)
		})
		
		let addSmoke = SCNAction.run({_ in
			for smokeEmitter in self.smokeEmitterArray {
				smokeEmitter.addParticleSystem(self.carSmokeParticleSystem)
			}
		})
		
		let viiiu = SCNAction.run({_ in
			//play viuuu sound (ko spelje avto)
		})
		
		car1Node?.runAction(SCNAction.sequence([brrrm, driveCars, viiiu, addSmoke]))
		
	}
	
	func stopTheCars() {
		carsRemoveSmokeEffect()
		
		car1Node?.physicsBody?.velocity = SCNVector3Zero
		car1Node?.position = player1StartingPosition
		
		car2Node?.physicsBody?.velocity = SCNVector3Zero
		car2Node?.position = player2StartingPosition
	}
	
	func carsRemoveSmokeEffect() {
		for smokeEmitter in smokeEmitterArray {
			smokeEmitter.removeParticleSystem(carSmokeParticleSystem)
		}
	}
	
	//Sounds:
	
	func setupSounds() {
		loadSound("pop", fileNamed: "art.scnassets/Sounds/pop.wav")
		loadSound("explosion", fileNamed: "art.scnassets/Sounds/Explosion.wav")
	}
	
	func loadSound(_ name:String, fileNamed:String) {
		let sound = SCNAudioSource(fileNamed: fileNamed)!
		sound.load()
		sounds[name] = sound
	}
	
	func playSound(node:SCNNode?, name:String) {
		if node != nil {
			if let sound = sounds[name] { node!.runAction(SCNAction.playAudio(sound, waitForCompletion: true)) }
		}
	}
	
	
	//Touches:
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if gameState == .play {
			let touchLocation = touches.first?.location(in: scnView)
			for result in scnView.hitTest(touchLocation!, options: nil) {
				let nodesName = result.node.name
				
				if nodesName == Obstacle.inBarrier { // te dve stvari predolgo trajata, rajši bom dala oboje v slovar tipa String: [SCNNode]
					lastTouchedLocation = touchLocation!
					result.node.name = Obstacle.beingShot
					readyToShoot = true
				} else if nodesName == Obstacle.readyToBeExploded { explodeObstacle(obstacle: result.node, speedUpType: false) }
			}
		}
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		if gameState == .play {
			if readyToShoot {
				let velocity = calculateVelocity(point1: lastTouchedLocation, point2: (touches.first?.location(in: scnView))!)
				
				shotTheObstacle(atVelocity: velocity)
				readyToShoot = false
			}
		}
	}
	
	//Scene Renderer:
	
	func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
		if gameState == .play {
			let player1X = (car1Node?.presentation.position.x)!
			let player2X = (car2Node?.presentation.position.x)!
			let slowestCarX = player1X < player2X ? player1X : player2X
			mainCamera?.position.x = slowestCarX + 17.0
			
			barrier1?.position = SCNVector3(x: player1X + 1, y: 0, z: (car1Node?.presentation.position.z)!)
			barrier2?.position = SCNVector3(x: player2X + 1, y: 0, z: (car2Node?.presentation.position.z)!)
		}
	}
	
	//Physics Contact:
	
	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
		if gameState == .play {
			let nodeMaskA = contact.nodeA.physicsBody?.categoryBitMask
			let nodeMaskB = contact.nodeB.physicsBody?.categoryBitMask
			
			
			if nodeMaskA == PhysicsCategory.car {
				if nodeMaskB == PhysicsCategory.obstacle { obstacleCollidedWithCar(car: contact.nodeA, obstacle: contact.nodeB) }
				else if nodeMaskB == PhysicsCategory.finishLine { gameOver(carWon: contact.nodeA, atFinishLine: true) }
			} else if nodeMaskB == PhysicsCategory.car {
				if nodeMaskA == PhysicsCategory.obstacle { obstacleCollidedWithCar(car: contact.nodeB, obstacle: contact.nodeA) }
				else if nodeMaskA == PhysicsCategory.finishLine { gameOver(carWon: contact.nodeB, atFinishLine: true) }
				
			} else if nodeMaskA == PhysicsCategory.barrier {
				obstacleInBarrier(barrier: contact.nodeA, obstacle: contact.nodeB)
			} else if nodeMaskB == PhysicsCategory.barrier {
					obstacleInBarrier(barrier: contact.nodeB, obstacle: contact.nodeA)
			
			} else if nodeMaskA == PhysicsCategory.borderLine { explodeObstacle(obstacle: contact.nodeB, speedUpType: false) }
			else if nodeMaskB == PhysicsCategory.borderLine { explodeObstacle(obstacle: contact.nodeA, speedUpType: false) }
		}
	}
	
	
	//Unrelevant variables and methods:
	
    override var shouldAutorotate: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("memory warning")
    }
}
