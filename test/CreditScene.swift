//
//  Credits.swift
//  test
//
//  Created by Jonah Gorski on 6/27/26.
//

import SpriteKit
import GameplayKit
import AppKit

class CreditScene : SKScene, NSTextFieldDelegate {
    var exitButton = NSButton()
    override func didMove(to scene: SKView) {
        exitButton = NSButton(title: "Exit", target: self, action: #selector(buttonGroupTapped(_:)))
        exitButton.setButtonType(.momentaryPushIn)
        exitButton.bezelStyle = .rounded
    }
    @objc func buttonGroupTapped(_ sender: NSButton) {
        print("button, tapped.")
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
