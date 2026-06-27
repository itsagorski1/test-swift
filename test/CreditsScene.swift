//
//  Credits.swift
//  test
//
//  Created by Jonah Gorski on 6/27/26.
//

import SpriteKit
import GameplayKit
import AppKit

class CreditsScene : SKScene, NSTextFieldDelegate {
    var exitButton = NSButton()

    override func willMove(from view: SKView) {
        exitButton.removeFromSuperview()
    }

    override func didMove(to view: SKView) {
        let author = SKLabelNode(text: "Author: Jonah Gorski")
        let githubUserText = SKLabelNode(text: "Jonah Gorski on GitHub:")
        let githubUserLink = SKLabelNode(text: "https://github.com/itsagorski1/")
        let githubLink = SKLabelNode(text: "https://github.com/itsagorski1/test-swift")
        
        author.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 63)
        githubUserText.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 21)
        githubUserLink.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 21)
        githubLink.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 63)
        
        author.fontColor = .white
        githubUserText.fontColor = .white
        githubUserLink.fontColor = .white
        githubLink.fontColor = .white
        
        author.fontSize = 32
        githubUserText.fontSize = 32
        githubUserLink.fontSize = 32
        githubLink.fontSize = 32
        
        self.addChild(author)
        self.addChild(githubUserText)
        self.addChild(githubUserLink)
        self.addChild(githubLink)
        
        exitButton = NSButton(title: "Exit", target: self, action: #selector(buttonGroupTapped(_:)))
        exitButton.setButtonType(.momentaryPushIn)
        exitButton.bezelStyle = .rounded
        exitButton.frame = CGRect(x: 20, y: 20, width: 120, height: 32)
        view.addSubview(exitButton)
    }
    @objc func buttonGroupTapped(_ sender: NSButton) {
        let targetSize = self.size // Match the current window size
        let incomingScene = IntroScene(size: targetSize)
        incomingScene.scaleMode = .resizeFill
        
        // 2. Define an animated transition style (e.g., crossfade)
        let transition = SKTransition.crossFade(withDuration: 1.0)
        if let skView = self.view {
            print("Deactivating IntroScene... Presenting GameScene.")
            skView.presentScene(incomingScene, transition: transition)
        }
    }
}
