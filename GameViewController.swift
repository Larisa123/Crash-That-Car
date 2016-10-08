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
	static let car1: Int = 2
	static let car2: Int = 4
	static let barrier: Int = 8
	static let obstacle: Int = 16
	static let line: Int = 32
	//static let Floor: Int = 64
}

let pi = Float(M_PI)

enum GameState { //not finite
	case start
	case play
	case gameOver
}

import UIKit
import QuartzCore
import SceneKit


class GameViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate {
	var scnView: SCNView!
	var raceScene: SCNScene?
	
	var player1Car: SCNNode?
	var player2Car: SCNNode?
	var obstacleArray: [SCNNode] = []
	let obstacleVelocity: Float = 10
	var readyToShoot: Bool = false
	

	
	var mainCameraSelfieStick: SCNNode?
	var mainCamera: SCNNode?
	
	//Playground:
	let playgroundX: Float = 40 // ?
	let playgroundZ: Float = 20
	
	var lastTouchedLocation = CGPoint.zero
	var timeSinceLastTap: TimeInterval = 0
	
	var gameState: GameState = .start
	var tutorialFinished: Bool = false
	

    override func viewDidLoad() {
        super.viewDidLoad()
        
		setupView()
		setupScene()
		setupCars()
		setupCarBarriers()
		setupLines()
		setupCameras()
		setupParticleEffects()
		setupObstacles()
    }
	
	//Setups:
	
	func setupView() {
		scnView = self.view as! SCNView!
		scnView.delegate = self
	}
	
	func setupScene() {
		raceScene = SCNScene(named: "art.scnassets/Scenes/raceScene.scn")
		scnView.scene = raceScene
		raceScene?.physicsWorld.contactDelegate = self
	}
	
	func setupCars() {
		player1Car = raceScene?.rootNode.childNode(withName: "player1Car reference", recursively: true)
		player2Car = raceScene?.rootNode.childNode(withName: "player2Car reference", recursively: true)
		
		for car in [player1Car, player2Car] { car?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil) }
		player1Car?.physicsBody?.categoryBitMask = PhysicsCategory.car1
		player2Car?.physicsBody?.categoryBitMask = PhysicsCategory.car2
		
		for car in [player1Car, player2Car] {
			car?.physicsBody?.collisionBitMask = PhysicsCategory.floor
			car?.physicsBody?.contactTestBitMask = PhysicsCategory.line | PhysicsCategory.obstacle
			car?.physicsBody?.damping = 0
		}

	}
	
	func setupCarBarriers() {
		let player1CarBarrier = raceScene?.rootNode.childNode(withName: "player1Barrier", recursively: true)
		let player2CarBarrier = raceScene?.rootNode.childNode(withName: "player2Barrier", recursively: true)
		
		for barrier in [player1CarBarrier, player2CarBarrier] {
			barrier?.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
			barrier?.physicsBody?.categoryBitMask = PhysicsCategory.barrier
			barrier?.physicsBody?.collisionBitMask = PhysicsCategory.none
			barrier?.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
		}
	}
	
	func setupLines() {
		raceScene?.rootNode.enumerateChildNodes { node, stop in
			if node.name == "line" {
				node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
				node.physicsBody?.categoryBitMask = PhysicsCategory.line
				node.physicsBody?.collisionBitMask = PhysicsCategory.car1 | PhysicsCategory.car2
			}
		}
	}
	
	func setupParticleEffects() {
		
	}
	
	func setupCameras() {
		mainCameraSelfieStick = raceScene?.rootNode.childNode(withName: "mainCameraSelfieStick", recursively: true)
		mainCamera = raceScene?.rootNode.childNode(withName: "mainCamera", recursively: true)
		scnView.pointOfView = mainCamera
	}
	
	func setupObstacles() {
		let randomColors: [UIColor] = [UIColor.blue,  UIColor.red,  UIColor.yellow,  UIColor.gray]
		let obstacleScene = SCNScene(named: "art.scnassets/Scenes/obstacleNormal.scn")
		let obstacle = obstacleScene?.rootNode.childNode(withName: "obstacle", recursively: true)
		
		for sign: Float in [-1, 1] {
			for i in 1...15 {
				let randomPosition = SCNVector3(x: Float(i) * 3.5, y: 0.15, z: sign * Float(arc4random_uniform(UInt32(Int(playgroundZ/2 - 2.0))) + 1))
				let randomColor = randomColors[Int(arc4random_uniform(UInt32(3)))]
				
				let obstacleCopy = obstacle?.clone()
				obstacleCopy?.geometry = obstacle?.geometry?.copy() as? SCNGeometry
				obstacleCopy?.position = randomPosition
				obstacleCopy?.geometry?.materials.first?.diffuse.contents = randomColor
				obstacleCopy?.eulerAngles = SCNVector3(x: 10.0 * Float(i), y: Float(30 - i), z: 5.0 * Float(i) * sign) //malo na random
				
				obstacleCopy?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
				obstacleCopy?.physicsBody?.isAffectedByGravity = false
				obstacleCopy?.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
				obstacleCopy?.physicsBody?.collisionBitMask = PhysicsCategory.none
				obstacleCopy?.physicsBody?.contactTestBitMask = PhysicsCategory.car1 | PhysicsCategory.car2 | PhysicsCategory.barrier
				
				obstacleArray.append(obstacleCopy!)
				raceScene!.rootNode.addChildNode(obstacleCopy!)
			}
		}
	}
	
	//Game:
	
	func checkIfGameIsFinished(car: SCNNode, line: SCNNode) {
	}
	
	func obstacleCollidedWithCar(car: SCNNode, obstacle: SCNNode) {
		//gameOver! bring a table!
		//print("game over!") //for now
		//gameState = .gameOver
	}
	
	func obstacleInBarrier(barrier: SCNNode, obstacle: SCNNode) {
		if obstacle.name == "obstacle" {
			obstacle.name = "obstacleReadyToBeShot" //with this name set, player can shot (drag) this obstacle, when he does that, its name becomes "obstacleShot"
		} else if obstacle.name == "obstacleShot" {
			obstacle.geometry?.materials.first?.diffuse.contents = UIColor.red
			obstacle.name = "obstacleReadyToBeRemoved"
		}
	}
	
	func calculateVelocity(point1: CGPoint, point2: CGPoint) -> SCNVector3 {
		let deltaY = Float(point1.y) - Float(point2.y)
		var angle = atan(deltaY / Float((point2.x - point1.x)))
		
		if point2.x < point1.x {
			if deltaY > 0 { angle -= pi/2 }
			else if deltaY < 0 { angle += pi/2 }
		} else if point2.x > point1.x {
			if deltaY > 0 { angle -= pi/2 }
			else if deltaY < 0 { angle += pi/2 }
		}
			
		return SCNVector3(obstacleVelocity * cos(angle), 0,  obstacleVelocity * sin(angle))
	}
	
	func shotTheObstacle(atVelocity velocity: SCNVector3) {
		for obstacle in obstacleArray {
			if obstacle.name == "obstacleInShot" {
				obstacle.physicsBody?.velocity = velocity
				obstacle.name = "obstacleShot"
			}
		}
	}
	
	//Touches:
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		if gameState == .start { //for now
			player1Car?.physicsBody?.velocity = SCNVector3(3, 0, 0)
			player2Car?.physicsBody?.velocity = SCNVector3(3, 0, 0)
			gameState = .play
		} else if gameState == .play {
			for touch in touches {
				for result in scnView.hitTest(touch.location(in: scnView), options: nil) {
					if result.node.name == "obstacleReadyToBeShot" {
						lastTouchedLocation = touch.location(in: scnView)
						timeSinceLastTap = (event?.timestamp)!
						result.node.name = "obstacleInShot"
						readyToShoot = true
					}
				}
			}
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
		
	}
	
	//Physics Contact:
	
	func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
		
		let nodeMaskA = contact.nodeA.physicsBody?.categoryBitMask
		let nodeMaskB = contact.nodeB.physicsBody?.categoryBitMask
		//print(nodeMaskA, nodeMaskB)
		
		if nodeMaskA == PhysicsCategory.barrier { obstacleInBarrier(barrier: contact.nodeA, obstacle: contact.nodeB) }
		else if nodeMaskB == PhysicsCategory.barrier { obstacleInBarrier(barrier: contact.nodeB, obstacle: contact.nodeA) }
		else if (nodeMaskA == PhysicsCategory.car1 || nodeMaskA == PhysicsCategory.car2) {
			if nodeMaskB == PhysicsCategory.obstacle { obstacleCollidedWithCar(car: contact.nodeA, obstacle: contact.nodeB) }
			else if nodeMaskB == PhysicsCategory.line { checkIfGameIsFinished(car: contact.nodeA, line: contact.nodeB) }
		} else if (nodeMaskB == PhysicsCategory.car1 || nodeMaskB == PhysicsCategory.car2) && nodeMaskA == PhysicsCategory.obstacle {
			if nodeMaskA == PhysicsCategory.obstacle { obstacleCollidedWithCar(car: contact.nodeB, obstacle: contact.nodeA) }
			else if nodeMaskA == PhysicsCategory.line { checkIfGameIsFinished(car: contact.nodeB, line: contact.nodeA) }
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
