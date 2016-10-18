//
//  GameOverScene.swift
//  CrashThatCar
//
//  Created by Lara Carli on 10/8/16.
//  Copyright © 2016 Larisa Carli. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
	var gameViewController: GameViewController!
	var deviceSize: CGSize!
	
	var gameOverLabelSprite: SKSpriteNode!
	var player1WonSprite: SKSpriteNode!
	var player2WonSprite: SKSpriteNode!
	var replayButton: SKSpriteNode!
	var tapToPlayLogoSprite: SKSpriteNode!
	var tutorialLogoSprite: SKSpriteNode!
	var tutorialImageSprite: SKSpriteNode!
	var closeTutorialLogo: SKSpriteNode!
	
	var logo1: SKSpriteNode!
	var logo2: SKSpriteNode!
	var logo3: SKSpriteNode!
	var logo0: SKSpriteNode!
	
	init(gameViewController: GameViewController) {
		self.gameViewController = gameViewController
		self.deviceSize = gameViewController.deviceSize
		super.init(size: deviceSize)
		
		self.anchorPoint = CGPoint.zero
		//automatically resize to fill the viewport
		self.scaleMode = .resizeFill
		
		//make UI larger on iPads:
		
		let scale: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 0.9 : 0.6
		
		//setupMainTable()
		setupSprites(scale: scale)
	}

	
	func setupSprites(scale: CGFloat) {
		gameOverLabelSprite = SKSpriteNode(imageNamed: "gameOverLabel.png")
		gameOverLabelSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		gameOverLabelSprite.position = CGPoint(x: deviceSize.width/2, y: deviceSize.height * 0.85)
		gameOverLabelSprite.size.width *= scale
		gameOverLabelSprite.size.height *= scale
		addChild(gameOverLabelSprite)
		gameOverLabelSprite.isHidden = true
		
		player1WonSprite = SKSpriteNode(imageNamed: "player1Won.png")
		player2WonSprite = SKSpriteNode(imageNamed: "player2Won.png")
		
		for sprite in [player1WonSprite, player2WonSprite] {
			sprite?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
			sprite?.position = CGPoint(x: deviceSize.width/2, y: deviceSize.height * 0.55)
			sprite?.size.width *= scale * 1.3
			sprite?.size.height *= scale * 1.3
			addChild(sprite!)
			sprite?.isHidden = true
		}
		
		replayButton = SKSpriteNode(imageNamed: "replayLabel.png")
		replayButton.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		replayButton.position = CGPoint(x: deviceSize.width/2, y: deviceSize.height * 0.25)
		replayButton.size.width *= scale
		replayButton.size.height *= scale
		addChild(replayButton)
		replayButton.isHidden = true
		
		tapToPlayLogoSprite = SKSpriteNode(imageNamed: "tapToPlayLogo.png")
		tapToPlayLogoSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		tapToPlayLogoSprite.position = CGPoint(x: deviceSize.width/2, y: deviceSize.height/2)
		tapToPlayLogoSprite.size.width *= scale * 1.2
		tapToPlayLogoSprite.size.height *= scale * 1.2
		addChild(tapToPlayLogoSprite)
		tapToPlayLogoSprite.isHidden = true
		
		
		logo1 = SKSpriteNode(imageNamed: "logo1.png")
		logo2 = SKSpriteNode(imageNamed: "logo2.png")
		logo3 = SKSpriteNode(imageNamed: "logo3.png")
		logo0 = SKSpriteNode(imageNamed: "logo0.png")
		for logo in [logo1, logo2, logo3, logo0] {
			logo?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
			logo?.position = CGPoint(x: deviceSize.width/2, y: deviceSize.height/2)
			logo?.size.width *= scale * 2.0
			logo?.size.height *= scale * 2.0
			addChild(logo!)
			logo?.isHidden = true
		}
		
		tutorialLogoSprite = SKSpriteNode(imageNamed: "tutorialLogo.png")
		tutorialLogoSprite.anchorPoint = CGPoint(x: 1, y: 1)
		tutorialLogoSprite.position = CGPoint(x: deviceSize.width*0.95, y: deviceSize.height*0.95)
		addChild(tutorialLogoSprite)
		tutorialLogoSprite.isHidden = true
		
		tutorialImageSprite = SKSpriteNode(imageNamed: "tutorialImage.png")
		tutorialImageSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		tutorialImageSprite.position = CGPoint(x: deviceSize.width/2, y: deviceSize.height/2)
		addChild(tutorialImageSprite)
		tutorialImageSprite.size = deviceSize
		tutorialImageSprite.isHidden = true

		closeTutorialLogo = SKSpriteNode(imageNamed: "closeLogo.png")
		closeTutorialLogo.anchorPoint = CGPoint(x: 1, y: 1)
		closeTutorialLogo.position = CGPoint(x: deviceSize.width*0.95, y: deviceSize.height*0.95)
		addChild(closeTutorialLogo)
		closeTutorialLogo.isHidden = true
	}
	
	func popSpritesOnGameOver(carWon car: String) {
		let playerSprite = car == "first" ? player1WonSprite: player2WonSprite
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { self.pop(node: self.gameOverLabelSprite, withSound: true) })
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: { self.pop(node: playerSprite!, withSound: true) })
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { self.repeatPopForever(node: self.replayButton) })
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: { self.gameViewController.gameState = .gameOverTapToPlay })
	}
	
	func hideSprites() {
		gameOverLabelSprite.isHidden = true
		player1WonSprite.isHidden = true
		player2WonSprite.isHidden = true
		replayButton.removeAllActions()
		replayButton.isHidden = true
		tutorialLogoSprite.isHidden = true
	}
	
	func pop(node: SKSpriteNode, withSound: Bool) {
		let popAction: SKAction!
		
		node.isHidden = false
		if withSound {
			popAction = SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.1), SKAction.scale(to: 0.9, duration: 0.3)])
			node.run(SKAction.playSoundFileNamed("art.scnassets/Sounds/pop.wav", waitForCompletion: true))
		} else {
			popAction = SKAction.sequence([SKAction.scale(to: 1.15, duration: 0.2), SKAction.scale(to: 0.85, duration: 0.4)])
		}
		node.run(popAction)
	}
	
	func repeatPopForever(node: SKSpriteNode) {
		node.isHidden = false
		let popRepeatAction = SKAction.sequence([SKAction.scale(to: 1.1, duration: 1.0), SKAction.scale(to: 0.9, duration: 1.0)])
		node.run(SKAction.repeatForever(popRepeatAction))
		node.run(SKAction.playSoundFileNamed("art.scnassets/Sounds/pop.wav", waitForCompletion: true))

	}
	
	func showTapToPlayLogo() {
		tapToPlayLogoSprite.isHidden = false
		repeatPopForever(node: tapToPlayLogoSprite)
		gameViewController.gameState = .tapToPlay
		
		tutorialLogoSprite.isHidden = false
		
		if !gameViewController.tutorialFinished {
			let popRepeatAction = SKAction.sequence([SKAction.scale(to: 1.1, duration: 1.0), SKAction.scale(to: 0.9, duration: 1.0)])
			tutorialLogoSprite.run(SKAction.repeatForever(popRepeatAction))
		}
	}
	
	func hideTapToPlayLogo() {
		tapToPlayLogoSprite.removeAllActions()
		tapToPlayLogoSprite.isHidden = true
		
		tutorialLogoSprite.isHidden = true
	}
	
	func showTutorial() {
		hideTapToPlayLogo()
		tutorialImageSprite.isHidden = false
		closeTutorialLogo.isHidden = false
		repeatPopForever(node: closeTutorialLogo)
		gameViewController.gameState = .showingTutorial
		
		gameViewController.tutorialFinished = true
	}
	
	func hideTutorial() {
		tutorialImageSprite.isHidden = true
		closeTutorialLogo.isHidden = true
		tutorialLogoSprite.removeAllActions()
		showTapToPlayLogo()
	}
	
	func countDown() {
		gameViewController.gameState = .countDown
		
		hideTapToPlayLogo()
		gameViewController.scnView.pointOfView = gameViewController.mainCamera
		
		run(SKAction.sequence([SKAction.wait(forDuration: 0.6),  SKAction.playSoundFileNamed("art.scnassets/Sounds/countdown.wav", waitForCompletion: true)]))
		run(SKAction.sequence([SKAction.wait(forDuration: 4.4),  SKAction.playSoundFileNamed("art.scnassets/Sounds/cheer.wav", waitForCompletion: true)]))
		
		var delayTime = 0.6
		
		for logo in  [logo3, logo2, logo1, logo0] {
			DispatchQueue.main.asyncAfter(deadline: .now() + delayTime, execute: {
				self.pop(node: logo!, withSound: false)
			})
			DispatchQueue.main.asyncAfter(deadline: .now() + delayTime + 0.7, execute: {
				logo?.isHidden = true
			})
			delayTime += 1.0
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + delayTime - 0.5, execute: {
			self.gameViewController.startTheGame()
		})
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			if gameViewController.gameState == .tapToPlay {
				if atPoint(touch.location(in: self)) == tutorialLogoSprite {
					showTutorial()
				} else {
					countDown()
				}
			} else if gameViewController.gameState == .showingTutorial { hideTutorial() }
			else if gameViewController.gameState == .gameOverTapToPlay {
				gameViewController.replayGame()
			}
		}
	}
	
	required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
}
