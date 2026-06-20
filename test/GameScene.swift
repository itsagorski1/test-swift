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

class GameScene: SKScene, NSTextFieldDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var lineNode : SKShapeNode?
    
    let width = NSTextField()
    let boxLengthField = NSTextField()
    let boxHeightField = NSTextField()
    var width4rl = 50 // Default width to 50 so it's visible right away
    var boxLength = 80
    var boxHeight = 50
    
    // --- SELECTION & DRAG TRACKING VARIABLES ---
    private var selectedNode: SKShapeNode? = nil
    private var isDragging = false
    
    func setupLengthInput(in view: SKView) {
        width.frame = CGRect(x: 20, y: 60, width: 80, height: 25)
        width.placeholderString = "Length"
        width.font = NSFont.systemFont(ofSize: 13)
        width.alignment = .center
        width.isBezeled = true
        width.bezelStyle = .roundedBezel
        width.delegate = self
        view.addSubview(width)
    }
    
    func setupBoxInputs(in view: SKView) {
        boxLengthField.frame = CGRect(x: 110, y: 60, width: 100, height: 25)
        boxLengthField.placeholderString = "Box width"
        boxLengthField.font = NSFont.systemFont(ofSize: 13)
        boxLengthField.alignment = .center
        boxLengthField.isBezeled = true
        boxLengthField.bezelStyle = .roundedBezel
        boxLengthField.delegate = self
        boxLengthField.isHidden = true
        view.addSubview(boxLengthField)
        
        boxHeightField.frame = CGRect(x: 220, y: 60, width: 100, height: 25)
        boxHeightField.placeholderString = "Box height"
        boxHeightField.font = NSFont.systemFont(ofSize: 13)
        boxHeightField.alignment = .center
        boxHeightField.isBezeled = true
        boxHeightField.bezelStyle = .roundedBezel
        boxHeightField.delegate = self
        boxHeightField.isHidden = true
        view.addSubview(boxHeightField)
    }
    
    override func willMove(from view: SKView) {
        width.removeFromSuperview()
        boxLengthField.removeFromSuperview()
        boxHeightField.removeFromSuperview()
        button1.removeFromSuperview()
        button2.removeFromSuperview()
        button3.removeFromSuperview()
    }
    
    // 1. Force the Mac window to drop focus when you hit Return/Enter
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            self.view?.window?.makeFirstResponder(self.view)
            return true
        }
        return false
    }
    
    // 2. This updates your numeric values after the user finishes editing a field.
    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        guard let value = Int(textField.stringValue) else {
            print("Please enter a valid whole number.")
            textField.stringValue = ""
            return
        }
        
        if textField === width {
            width4rl = value
            print("Width updated to: \(value)")
            redrawLine()
        } else if textField === boxLengthField {
            boxLength = value
            print("Box width updated to: \(value)")
        } else if textField === boxHeightField {
            boxHeight = value
            print("Box height updated to: \(value)")
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
        
        // Render your master template at starting defaults
        redrawLine()
    }
    
    // 4. Clean click actions that cleanly fade out individual clones
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.lineNode?.copy() as? SKShapeNode {
            n.name = "clone" // Unique marker name so we can filter and select it later
            n.position = pos
            n.strokeColor = SKColor(hex: 0x0000ff)
            n.fillColor = SKColor(hex: 0x0000ff)
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.lineNode?.copy() as? SKShapeNode {
            n.name = "clone"
            n.position = pos
            n.strokeColor = SKColor.blue
            n.fillColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.lineNode?.copy() as? SKShapeNode {
            n.name = "clone"
            n.position = pos
            n.strokeColor = SKColor.red
            n.fillColor = SKColor.red
            self.addChild(n)
        }
    }
    
    func createBox(at position: CGPoint) {
        let outerWidth = CGFloat(boxLength)
        let outerHeight = CGFloat(boxHeight)
        let inset: CGFloat = 4
        
        let outerBox = SKShapeNode(rectOf: CGSize(width: outerWidth, height: outerHeight))
        outerBox.name = "clone"
        outerBox.position = position
        outerBox.lineWidth = 2.5
        outerBox.fillColor = SKColor.white
        outerBox.strokeColor = SKColor.white
        
        let innerSize = CGSize(
            width: max(outerWidth - inset * 2, 1),
            height: max(outerHeight - inset * 2, 1)
        )
        let innerBox = SKShapeNode(rectOf: innerSize)
        innerBox.fillColor = SKColor.black
        innerBox.strokeColor = SKColor.black
        innerBox.lineWidth = 0
        
        outerBox.addChild(innerBox)
        self.addChild(outerBox)
    }
    
    // --- UPDATED MOUSE ACTIONS ---
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        
        if button1.state == .on {
            // Create Mode behavior
            self.touchDown(atPoint: location)
        }
        else if button2.state == .on {
            // Select Mode behavior
            let clickedNodes = self.nodes(at: location)
            
            // Look for the first node that is a clone shape
            if let targetNode = clickedNodes.first(where: { $0.name == "clone" }) as? SKShapeNode {
                
                // Clear out highlight colors on any previously selected item
                if let oldSelection = selectedNode, oldSelection != targetNode {
                    oldSelection.strokeColor = SKColor(hex: 0x0000ff)
                }
                
                selectedNode = targetNode
                isDragging = true
                
                // Turn selection orange to show visual feedback
                selectedNode?.strokeColor = SKColor.orange
            } else {
                // Clicking empty screen space clears current choice selection
                selectedNode?.strokeColor = SKColor(hex: 0x0000ff)
                selectedNode = nil
                isDragging = false
            }
        } else if button3.state == .on {
            createBox(at: location)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        let location = event.location(in: self)
        
        if button1.state == .on {
            self.touchMoved(toPoint: location)
        }
        else if button2.state == .on && isDragging {
            // Drag the chosen block dynamically across the coordinates
            selectedNode?.position = location
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        let location = event.location(in: self)
        
        if button1.state == .on {
            self.touchUp(atPoint: location)
        }
        else if button2.state == .on {
            isDragging = false
        }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x33: // Delete/Backspace Key
            if button2.state == .on, let nodeToDelete = selectedNode {
                nodeToDelete.removeFromParent()
                selectedNode = nil // Clear tracking memory reference
                print("Selected clone item deleted.")
            } else {
                // Default fallback: do nothing
                break
            }
        default:
            // Optional legacy key placement generator logic
            let mouseLocation = CGPoint(x: self.frame.midX, y: self.frame.midY)
            touchDown(atPoint: mouseLocation)
            touchUp(atPoint: mouseLocation)
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
    
    var button1 = NSButton()
    var button2 = NSButton()
    var button3 = NSButton()
    
    override func didMove(to view: SKView) {
        setupLengthInput(in: view)
        setupBoxInputs(in: view)
        
        // 1. Create Button 1 (Starts Active/Latched)
        button1 = NSButton(title: "Create", target: self, action: #selector(buttonGroupTapped(_:)))
        button1.setButtonType(.pushOnPushOff)
        button1.bezelStyle = .rounded
        button1.state = .on
        
        // 2. Create Button 2 (Starts Inactive/Unlatched)
        button2 = NSButton(title: "Select", target: self, action: #selector(buttonGroupTapped(_:)))
        button2.setButtonType(.pushOnPushOff)
        button2.bezelStyle = .rounded
        button2.state = .off
        
        button3 = NSButton(title: "Box", target: self, action: #selector(buttonGroupTapped(_:)))
        button3.setButtonType(.pushOnPushOff)
        button3.bezelStyle = .rounded
        button3.state = .off
        
        // 3. Add them to the SpriteKit View
        if let skView = self.view {
            button1.frame = CGRect(x: 20, y: 20, width: 120, height: 32)
            button2.frame = CGRect(x: 150, y: 20, width: 120, height: 32)
            button3.frame = CGRect(x: 280, y: 20, width: 120, height: 32)
            
            skView.addSubview(button1)
            skView.addSubview(button2)
            skView.addSubview(button3)
        }
    }
    
    // 4. Handle the Radio/Latch Logic Manually
    @objc func buttonGroupTapped(_ sender: NSButton) {
        sender.state = .on
        
        if sender == button1 {
            button2.state = .off
            button3.state = .off
            modeCreate()
        } else if sender == button2 {
            button1.state = .off
            button3.state = .off
            modeSelect()
        } else if sender == button3 {
            button1.state = .off
            button2.state = .off
            modeBox()
        }
    }
    
    func modeCreate() {
        print("Create mode")
        width.isHidden = false
        boxLengthField.isHidden = true
        boxHeightField.isHidden = true
        selectedNode?.strokeColor = SKColor(hex: 0x0000ff)
        selectedNode = nil
        isDragging = false
    }
    
    func modeSelect() {
        print("Select mode")
        width.isHidden = true
        boxLengthField.isHidden = true
        boxHeightField.isHidden = true
    }
    
    func modeBox() {
        print("Box-create mode")
        width.isHidden = true
        boxLengthField.isHidden = false
        boxHeightField.isHidden = false
        selectedNode?.strokeColor = SKColor(hex: 0x0000ff)
        selectedNode = nil
        isDragging = false
    }
}
