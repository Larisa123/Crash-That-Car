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
	//var mainTableSprite: SKSpriteNode!
	
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
	
	/*
	func setupMainTable() {
		mainTableSprite = SKSpriteNode(imageNamed: "square.png")
		mainTableSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		mainTableSprite.position = CGPoint(x: deviceSize.width/2, y: deviceSize.height/2)
		addChild(mainTableSprite)
	}*/
	
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
			sprite?.size.width *= scale * 1.1
			sprite?.size.height *= scale * 1.1
			addChild(sprite!)
			sprite?.isHidden = true
		}
		
		replayButton = SKSpriteNode(imageNamed: "replayLabel")
		replayButton.anchorPoint = CGPoint(x: 0.5, y: 0.5)
		replayButton.position = CGPoint(x: deviceSize.width/2, y: deviceSize.height * 0.25)
		replayButton.size.width *= scale
		replayButton.size.height *= scale
		addChild(replayButton)
		replayButton.isHidden = true
		
	}
	
	func popSpritesOnGameOver(playerWon player: String) {
		let playerSprite = player == "first" ? player1WonSprite: player2WonSprite
		
		let popGameOverLabel = SKAction.run({node in
			self.gameOverLabelSprite.isHidden = false
			self.pop(node: self.gameOverLabelSprite)
		})
		let popPlayerWon = SKAction.run({node in
			playerSprite?.isHidden = false
			self.pop(node: playerSprite!)
		})
		let popReplayButton = SKAction.run({node in
			self.replayButton.isHidden = false
			let popRepeatAction = SKAction.repeatForever(SKAction.sequence([SKAction.scale(by: 1.1, duration: 1.0), SKAction.scale(by: 0.9, duration: 1.0)]))
			self.replayButton.run(popRepeatAction)
			self.replayButton.run(SKAction.playSoundFileNamed("art.scnassets/Sounds/pop.wav", waitForCompletion: true))
		})
		
		let waitAction = SKAction.wait(forDuration: 0.8)
		
		run(SKAction.sequence([popGameOverLabel, waitAction, popPlayerWon, waitAction, popReplayButton]))
	}
	
	func hideSprites() {
		gameOverLabelSprite.isHidden = true
		player1WonSprite.isHidden = true
		player2WonSprite.isHidden = true
		replayButton.removeAllActions()
		replayButton.isHidden = true
	}
	
	func pop(node: SKSpriteNode) {
		let popAction = SKAction.sequence([SKAction.scale(to: 1.1, duration: 0.1), SKAction.scale(to: 0.9, duration: 0.3)])
		node.run(popAction)
		//gameViewController.playSound(node: gameViewController.mainCameraSelfieStick, name: "pop") //an SCNNode has to play the song, node is SKSpriteNode and can not play it
		node.run(SKAction.playSoundFileNamed("art.scnassets/Sounds/pop.wav", waitForCompletion: true))
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			if(nodes(at: touch.location(in: self)).first == replayButton) {
				gameViewController.replayGame()
			}
		}
	}
	
	required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
}
