//
//  GameScene.swift
//  test
//
//  Created by Jonah Gorski on 6/15/26.
//

import SpriteKit
import GameplayKit
import AppKit

extension SKColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

<<<<<<< HEAD
class GameScene: SKScene, NSTextFieldDelegate {
=======
class GameScene: SKScene {
>>>>>>> 4907321052d86f69de6e22511c449be1aa755390
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var lineNode : SKShapeNode?
    
    let width = NSTextField()
    var width4rl = 50 // Default width to 50 so it's visible right away
        
    override func didMove(to view: SKView) {
        setupLengthInput(in: view)
    }
    
    func setupLengthInput(in view: SKView) {
        width.frame = CGRect(x: 20, y: 20, width: 80, height: 25)
        width.placeholderString = "Length"
        width.font = NSFont.systemFont(ofSize: 13)
        width.alignment = .center
        width.isBezeled = true
        width.bezelStyle = .roundedBezel
        width.delegate = self
        view.addSubview(width)
    }
    
    override func willMove(from view: SKView) {
        width.removeFromSuperview()
    }
    
    // 1. Force the Mac window to drop focus when you hit Return/Enter
    func control(_ control: NSControl, textView: NSText, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            self.view?.window?.makeFirstResponder(self.view)
            return true
        }
        return false
    }
    
    // 2. This updates your internal number value and recreates the shape geometry
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        
        if let value = Int(textField.stringValue) {
            self.width4rl = value
            if textField === width {
                print("Width updated to: \(value)")
                redrawLine()
            }
        } else {
            print("Please enter a valid whole number.")
        }
        textField.stringValue = ""
    }
    
    // 3. This function dynamically redraws the master line template path
    func redrawLine() {
        if self.lineNode == nil {
            self.lineNode = SKShapeNode()
            // Hide the original offscreen so it doesn't clutter your scene center
            self.lineNode?.position = CGPoint(x: -9999, y: -9999)
            self.addChild(self.lineNode!)
        }
        
        // Build a fresh visible bounding rectangle path using your custom input width
        let rectPath = CGPath(rect: CGRect(x: CGFloat(-self.width4rl / 2), y: -10, width: CGFloat(self.width4rl), height: 20), transform: nil)
        
        self.lineNode?.path = rectPath
        self.lineNode?.lineWidth = 2.5
        self.lineNode?.fillColor = SKColor.white  // Essential for visibility!
        self.lineNode?.strokeColor = SKColor.white
    }
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
<<<<<<< HEAD
        // Render your master template at starting defaults
        redrawLine()
=======
        // Create shape node to use during mouse interaction
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: 500, height: 1), cornerRadius: 0)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
>>>>>>> 4907321052d86f69de6e22511c449be1aa755390
    }
    
    // 4. Clean click actions that cleanly fade out individual clones
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.lineNode?.copy() as? SKShapeNode {
            n.position = pos
            n.strokeColor = SKColor(hex: 0x0000ff)
<<<<<<< HEAD
            n.fillColor = SKColor(hex: 0x0000ff)
=======
>>>>>>> 4907321052d86f69de6e22511c449be1aa755390
            self.addChild(n)
            
            // Fade and destroy the clone instance, keeping your template intact
            n.run(SKAction.sequence([]))
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
<<<<<<< HEAD
        if let n = self.lineNode?.copy() as? SKShapeNode {
            n.position = pos
            n.strokeColor = SKColor.blue
            n.fillColor = SKColor.blue
            self.addChild(n)
            
            n.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
=======
        for _ in 1...10 {
            if let n = self.spinnyNode?.copy() as! SKShapeNode? {
                n.position = pos
                n.strokeColor = SKColor.blue
                self.addChild(n)
            }
>>>>>>> 4907321052d86f69de6e22511c449be1aa755390
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.lineNode?.copy() as? SKShapeNode {
            n.position = pos
            n.strokeColor = SKColor.red
            n.fillColor = SKColor.red
            self.addChild(n)
            
            n.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        self.touchDown(atPoint: event.location(in: self))
    }
    
    override func mouseUp(with event: NSEvent) {
        self.touchUp(atPoint: event.location(in: self))
    }
    
    override func keyDown(with event: NSEvent) {
        let mouseLocation = CGPoint(x: self.frame.midX, y: self.frame.midY)
<<<<<<< HEAD
        touchDown(atPoint: mouseLocation)
        touchUp(atPoint: mouseLocation)
        
=======
        for _ in 1...10 {
            touchDown(atPoint: mouseLocation)
            touchUp(atPoint: mouseLocation)
        }
>>>>>>> 4907321052d86f69de6e22511c449be1aa755390
        switch event.keyCode {
        case 0x33:
            self.lineNode?.removeFromParent()
        default:
            break
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        let dt = currentTime - self.lastUpdateTime
        
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
}
