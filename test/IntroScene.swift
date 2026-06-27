import SpriteKit

class IntroScene: SKScene {
    var creditsButton = NSButton()
    override func didMove(to view: SKView) {
        // Build an intro title label
        let startLabel = SKLabelNode(text: "The Mainframe")
        let githubStart = SKLabelNode(text: "Github:")
        let githubLink = SKLabelNode(text: "https://github.com/itsagorski1/test-swift")
        startLabel.position = CGPoint(x: self.frame.midX, y: (self.frame.midY + 52))
        startLabel.fontColor = .white
        startLabel.fontSize = 100
        self.addChild(startLabel)
        githubStart.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        githubStart.fontColor = .white
        githubStart.fontSize = 32
        self.addChild(githubStart)
        githubLink.position = CGPoint(x: self.frame.midX, y: (self.frame.midY - 42) )
        githubLink.fontColor = SKColor(red: 15/255.0, green: 15/255.0, blue: 229/255.0, alpha: 1.0)
        startLabel.fontSize = 32
        self.addChild(githubLink)
        creditsButton = NSButton(title: "Credits", target: self, action: #selector(buttonGroupTapped(_:)))
        creditsButton.setButtonType(.momentaryPushIn)
        creditsButton.bezelStyle = .rounded
        creditsButton.state = .on
        if let skView = self.view {
            creditsButton.frame = CGRect(x: 20, y: 20, width: 120, height: 32)
            
            skView.addSubview(creditsButton)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        // --- DEACTIVATE INTRO AND ACTIVATE GAMESCENE ---
        
        // 1. Create the incoming game scene instance
        let targetSize = self.size // Match the current window size
        let incomingScene = GameScene(size: targetSize)
        incomingScene.scaleMode = .resizeFill
        
        // 2. Define an animated transition style (e.g., crossfade)
        let transition = SKTransition.crossFade(withDuration: 1.0)
        if let skView = self.view {
            print("Deactivating IntroScene... Presenting GameScene.")
            skView.presentScene(incomingScene, transition: transition)
        }
    }
    
    @objc func buttonGroupTapped(_ sender: NSButton) {
        print("clicked")
        let targetSize = self.size // Match the current window size
        let incomingScene = CreditScene(size: targetSize)
        incomingScene.scaleMode = .resizeFill
        
        // 2. Define an animated transition style (e.g., crossfade)
        let transition = SKTransition.crossFade(withDuration: 1.0)
        if let skView = self.view {
            print("Deactivating IntroScene... Presenting GameScene.")
            skView.presentScene(incomingScene, transition: transition)
        }

    }
}
// 504 (l)x32 (h)
