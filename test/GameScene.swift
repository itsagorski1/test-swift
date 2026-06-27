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

enum ComponentType: String {
    case networker
    case computer
    case printerScannerCopier
    case screen

    var buttonTitle: String {
        switch self {
        case .networker: return "Networker"
        case .computer: return "Computer"
        case .printerScannerCopier: return "Printer"
        case .screen: return "Screen"
        }
    }

    var title: String {
        switch self {
        case .networker: return "Networker"
        case .computer: return "Computer"
        case .printerScannerCopier: return "Printer/Scanner/Copier"
        case .screen: return "Screen"
        }
    }

    var subtitle: String {
        switch self {
        case .networker: return "Routes packets"
        case .computer: return "macOS Tahoe, latest software, best M-chip"
        case .printerScannerCopier: return "Prints, scans, copies"
        case .screen: return "Controlled by a computer"
        }
    }

    var size: CGSize {
        switch self {
        case .networker: return CGSize(width: 150, height: 76)
        case .computer: return CGSize(width: 240, height: 86)
        case .printerScannerCopier: return CGSize(width: 220, height: 86)
        case .screen: return CGSize(width: 170, height: 96)
        }
    }

    var fillColor: SKColor {
        switch self {
        case .networker: return SKColor(hex: 0x14315C)
        case .computer: return SKColor(hex: 0x263447)
        case .printerScannerCopier: return SKColor(hex: 0x3E342A)
        case .screen: return SKColor(hex: 0x16251D)
        }
    }

    var strokeColor: SKColor {
        switch self {
        case .networker: return SKColor(hex: 0x4CC9F0)
        case .computer: return SKColor(hex: 0xA8DADC)
        case .printerScannerCopier: return SKColor(hex: 0xF2CC8F)
        case .screen: return SKColor(hex: 0x95D5B2)
        }
    }

    var maxConnections: Int {
        switch self {
        case .networker: return 8
        case .computer: return 3
        case .printerScannerCopier: return 1
        case .screen: return 1
        }
    }

    func canWire(to other: ComponentType) -> Bool {
        switch (self, other) {
        case (.networker, .networker), (.networker, .computer), (.networker, .printerScannerCopier):
            return true
        case (.computer, .networker), (.computer, .printerScannerCopier), (.computer, .screen):
            return true
        case (.printerScannerCopier, .networker), (.printerScannerCopier, .computer):
            return true
        case (.screen, .computer):
            return true
        default:
            return false
        }
    }
}

struct WireConnection {
    let from: SKShapeNode
    let to: SKShapeNode
    let node: SKShapeNode
}

class GameScene: SKScene, NSTextFieldDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var lineNode : SKShapeNode?
    private let gridSize: CGFloat = 32
    private var wires = [WireConnection]()
    private var pendingWireStart: SKShapeNode? = nil
    private var nextComponentID = 1
    
    let widthField = NSTextField()
    let textField = NSTextField()
    var text = ""
    var width = 50 // Default width to 50 so it's visible right away
    var selectedComponentType: ComponentType = .networker
    
    // --- SELECTION & DRAG TRACKING VARIABLES ---
    private var selectedNode: SKShapeNode? = nil
    private var isDragging = false
    
    func setupLengthInput(in view: SKView) {
        widthField.frame = CGRect(x: 20, y: 60, width: 80, height: 25)
        widthField.placeholderString = "Length"
        widthField.font = NSFont.systemFont(ofSize: 13)
        widthField.alignment = .center
        widthField.isBezeled = true
        widthField.bezelStyle = .roundedBezel
        widthField.delegate = self
        view.addSubview(widthField)
    }
    
    override func willMove(from view: SKView) {
        widthField.removeFromSuperview()
        button1.removeFromSuperview()
        button2.removeFromSuperview()
        button3.removeFromSuperview()
        networkerButton.removeFromSuperview()
        computerButton.removeFromSuperview()
        printerButton.removeFromSuperview()
        screenButton.removeFromSuperview()
    }
    func setupTextField(in view: SKView, at pos: CGPoint) {
        textField.frame = CGRect(x: pos.x, y: pos.y, width: 80, height: 25)
        textField.placeholderString = "Length"
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.alignment = .center
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.delegate = self
        view.addSubview(textField)
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
        if textField === self.textField { text = textField.stringValue; print("text made") }
        guard let value = Int(textField.stringValue) else {
            print("Please enter a valid whole number.")
            textField.stringValue = ""
            return
        }
        
        if textField === widthField {
            width = value
            print("Width updated to: \(value)")
            redrawLine()
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
        let rectPath = CGPath(rect: CGRect(x: CGFloat(-self.width / 2), y: -10, width: CGFloat(self.width), height: 20), transform: nil)
        
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

    override func didChangeSize(_ oldSize: CGSize) {
        drawGrid()
        updateAllWires()
    }

    func drawGrid() {
        childNode(withName: "grid")?.removeFromParent()

        let gridNode = SKNode()
        gridNode.name = "grid"
        gridNode.zPosition = -100

        let lineColor = SKColor(white: 0.2, alpha: 0.45)
        var x: CGFloat = 0
        while x <= size.width {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            let line = SKShapeNode(path: path)
            line.strokeColor = lineColor
            line.lineWidth = 1
            gridNode.addChild(line)
            x += gridSize
        }

        var y: CGFloat = 0
        while y <= size.height {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            let line = SKShapeNode(path: path)
            line.strokeColor = lineColor
            line.lineWidth = 1
            gridNode.addChild(line)
            y += gridSize
        }

        addChild(gridNode)
    }

    func snapToGrid(_ position: CGPoint) -> CGPoint {
        CGPoint(
            x: round(position.x / gridSize) * gridSize,
            y: round(position.y / gridSize) * gridSize
        )
    }
    
    // 4. Clean click actions that cleanly fade out individual clones
    func touchDown(atPoint pos : CGPoint) {
        handleWireClick(at: pos)
    }
    
    func touchUp(atPoint pos : CGPoint) {
        // Wires are made with two clicks, so mouse-up does not create anything.
    }
    
    func createComponent(_ type: ComponentType, at position: CGPoint) {
        let component = SKShapeNode(rectOf: type.size, cornerRadius: 8)
        component.name = "clone"
        component.position = snapToGrid(position)
        component.lineWidth = 3
        component.fillColor = type.fillColor
        component.strokeColor = type.strokeColor
        component.zPosition = 10
        component.userData = NSMutableDictionary()
        component.userData?["componentType"] = type.rawValue
        component.userData?["componentID"] = nextComponentID
        nextComponentID += 1
        rememberDefaultStroke(for: component)

        let titleLabel = SKLabelNode(text: type.title)
        titleLabel.fontName = "Menlo-Bold"
        titleLabel.fontSize = 15
        titleLabel.fontColor = .white
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 12)

        let subtitleLabel = SKLabelNode(text: type.subtitle)
        subtitleLabel.fontName = "Menlo"
        subtitleLabel.fontSize = 9
        subtitleLabel.fontColor = SKColor(white: 0.88, alpha: 1)
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.position = CGPoint(x: 0, y: -14)

        let statusLabel = SKLabelNode(text: "offline")
        statusLabel.name = "statusLabel"
        statusLabel.fontName = "Menlo-Bold"
        statusLabel.fontSize = 9
        statusLabel.fontColor = SKColor(hex: 0xE76F51)
        statusLabel.verticalAlignmentMode = .center
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.position = CGPoint(x: 0, y: -type.size.height / 2 + 12)

        if type == .screen {
            let screenFace = SKShapeNode(rectOf: CGSize(width: type.size.width - 24, height: 38), cornerRadius: 5)
            screenFace.fillColor = SKColor(hex: 0x081C15)
            screenFace.strokeColor = SKColor(hex: 0x95D5B2)
            screenFace.lineWidth = 1.5
            screenFace.position = CGPoint(x: 0, y: 12)
            screenFace.name = "screenFace"

            let screenText = SKLabelNode(text: "No signal")
            screenText.name = "screenText"
            screenText.fontName = "Menlo-Bold"
            screenText.fontSize = 10
            screenText.fontColor = SKColor(hex: 0x95D5B2)
            screenText.verticalAlignmentMode = .center
            screenText.horizontalAlignmentMode = .center
            screenText.position = CGPoint.zero
            screenFace.addChild(screenText)
            component.addChild(screenFace)

            titleLabel.position = CGPoint(x: 0, y: -16)
            subtitleLabel.isHidden = true
        }

        component.addChild(titleLabel)
        component.addChild(subtitleLabel)
        component.addChild(statusLabel)
        self.addChild(component)
        updateNetworkStatus()
    }

    func rememberDefaultStroke(for node: SKShapeNode) {
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["defaultStrokeColor"] = node.strokeColor
    }

    func restoreDefaultStroke(for node: SKShapeNode?) {
        guard let node = node else { return }
        if let defaultColor = node.userData?["defaultStrokeColor"] as? SKColor {
            node.strokeColor = defaultColor
        }
    }

    func selectableShape(from node: SKNode) -> SKShapeNode? {
        var currentNode: SKNode? = node
        while let nodeToCheck = currentNode {
            if let shape = nodeToCheck as? SKShapeNode, shape.name == "clone" {
                return shape
            }
            currentNode = nodeToCheck.parent
        }
        return nil
    }

    func componentType(for node: SKShapeNode) -> ComponentType? {
        guard let rawValue = node.userData?["componentType"] as? String else { return nil }
        return ComponentType(rawValue: rawValue)
    }

    func componentID(for node: SKShapeNode) -> Int {
        node.userData?["componentID"] as? Int ?? 0
    }

    func handleWireClick(at position: CGPoint) {
        let clickedNodes = nodes(at: position)
        guard let clickedComponent = clickedNodes.compactMap({ selectableShape(from: $0) }).first,
              componentType(for: clickedComponent) != nil else {
            restoreDefaultStroke(for: pendingWireStart)
            pendingWireStart = nil
            return
        }

        if pendingWireStart == nil {
            pendingWireStart = clickedComponent
            clickedComponent.strokeColor = SKColor.yellow
            return
        }

        guard let start = pendingWireStart else { return }
        if start == clickedComponent {
            restoreDefaultStroke(for: start)
            pendingWireStart = nil
            return
        }

        if canCreateWire(from: start, to: clickedComponent) {
            createWire(from: start, to: clickedComponent)
        }

        restoreDefaultStroke(for: start)
        pendingWireStart = nil
    }

    func canCreateWire(from first: SKShapeNode, to second: SKShapeNode) -> Bool {
        guard let firstType = componentType(for: first), let secondType = componentType(for: second) else {
            return false
        }

        if wires.contains(where: { ($0.from == first && $0.to == second) || ($0.from == second && $0.to == first) }) {
            print("Those components are already wired together.")
            return false
        }

        if connectionCount(for: first) >= firstType.maxConnections || connectionCount(for: second) >= secondType.maxConnections {
            print("One of those components has no free ports.")
            return false
        }

        if firstType.canWire(to: secondType) || secondType.canWire(to: firstType) {
            return true
        }

        print("That wiring does not make sense for these component types.")
        return false
    }

    func connectionCount(for component: SKShapeNode) -> Int {
        wires.filter { $0.from == component || $0.to == component }.count
    }

    func createWire(from first: SKShapeNode, to second: SKShapeNode) {
        let wire = SKShapeNode()
        wire.name = "wire"
        wire.zPosition = 1
        wire.strokeColor = SKColor(hex: 0x2A9D8F)
        wire.lineWidth = 4
        wire.lineCap = .round
        addChild(wire)

        let connection = WireConnection(from: first, to: second, node: wire)
        wires.append(connection)
        updateWire(connection)
        updateNetworkStatus()
    }

    func updateWire(_ connection: WireConnection) {
        let path = CGMutablePath()
        path.move(to: connection.from.position)
        path.addLine(to: connection.to.position)
        connection.node.path = path
    }

    func updateAllWires() {
        for wire in wires {
            updateWire(wire)
        }
    }

    func removeWires(connectedTo component: SKShapeNode) {
        let removedWires = wires.filter { $0.from == component || $0.to == component }
        for wire in removedWires {
            wire.node.removeFromParent()
        }
        wires.removeAll { $0.from == component || $0.to == component }
        updateNetworkStatus()
    }

    func connectedComponents(to component: SKShapeNode) -> [SKShapeNode] {
        wires.compactMap { wire in
            if wire.from == component { return wire.to }
            if wire.to == component { return wire.from }
            return nil
        }
    }

    func allComponents() -> [SKShapeNode] {
        children.compactMap { $0 as? SKShapeNode }.filter { componentType(for: $0) != nil }
    }

    func updateNetworkStatus() {
        let components = allComponents()
        for component in components {
            guard let type = componentType(for: component) else { continue }
            let neighbors = connectedComponents(to: component)
            let neighborTypes = neighbors.compactMap { componentType(for: $0) }
            let isWorking: Bool

            switch type {
            case .networker:
                isWorking = !neighbors.isEmpty
            case .computer:
                isWorking = neighborTypes.contains(.networker)
            case .printerScannerCopier:
                isWorking = neighborTypes.contains(.networker) || neighborTypes.contains(.computer)
            case .screen:
                isWorking = neighborTypes.contains(.computer)
            }

            setStatus(isWorking ? "online" : "offline", for: component, working: isWorking)
            updateScreen(component, isWorking: isWorking, neighbors: neighbors)
        }
    }

    func setStatus(_ text: String, for component: SKShapeNode, working: Bool) {
        guard let statusLabel = component.childNode(withName: "statusLabel") as? SKLabelNode else { return }
        statusLabel.text = text
        statusLabel.fontColor = working ? SKColor(hex: 0x95D5B2) : SKColor(hex: 0xE76F51)
    }

    func updateScreen(_ component: SKShapeNode, isWorking: Bool, neighbors: [SKShapeNode]) {
        guard componentType(for: component) == .screen,
              let screenText = component.childNode(withName: "//screenText") as? SKLabelNode else { return }

        if isWorking, let computer = neighbors.first(where: { componentType(for: $0) == .computer }) {
            screenText.text = "Computer #\(componentID(for: computer))"
        } else {
            screenText.text = "No signal"
        }
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
            if let targetNode = clickedNodes.compactMap({ selectableShape(from: $0) }).first {
                
                // Clear out highlight colors on any previously selected item
                if let oldSelection = selectedNode, oldSelection != targetNode {
                    restoreDefaultStroke(for: oldSelection)
                }
                
                selectedNode = targetNode
                isDragging = true
                
                // Turn selection orange to show visual feedback
                selectedNode?.strokeColor = SKColor.orange
            } else {
                // Clicking empty screen space clears current choice selection
                restoreDefaultStroke(for: selectedNode)
                selectedNode = nil
                isDragging = false
            }
        } else if button3.state == .on {
            createComponent(selectedComponentType, at: location)
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        let location = event.location(in: self)
        
        if button1.state == .on {
            //self.touchMoved(toPoint: location)
        }
        else if button2.state == .on && isDragging {
            // Drag the chosen block dynamically across the coordinates
            selectedNode?.position = snapToGrid(location)
            updateAllWires()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if button1.state == .on {
            // Wires are completed on mouse-down by picking two components.
        }
        else if button2.state == .on {
            isDragging = false
        }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 0x33: // Delete/Backspace Key
            if button2.state == .on, let nodeToDelete = selectedNode {
                removeWires(connectedTo: nodeToDelete)
                nodeToDelete.removeFromParent()
                selectedNode = nil // Clear tracking memory reference
                print("Selected clone item deleted.")
            } else {
                // Default fallback: do nothing
                break
            }
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
    
    var button1 = NSButton()
    var button2 = NSButton()
    var button3 = NSButton()
    var networkerButton = NSButton()
    var computerButton = NSButton()
    var printerButton = NSButton()
    var screenButton = NSButton()
    
    override func didMove(to view: SKView) {
        setupLengthInput(in: view)
        widthField.isHidden = true
        drawGrid()
        
        // 1. Create Button 1 (Starts Active/Latched)
        button1 = NSButton(title: "Wire", target: self, action: #selector(buttonGroupTapped(_:)))
        button1.setButtonType(.pushOnPushOff)
        button1.bezelStyle = .rounded
        button1.state = .on
        
        // 2. Create Button 2 (Starts Inactive/Unlatched)
        button2 = NSButton(title: "Select", target: self, action: #selector(buttonGroupTapped(_:)))
        button2.setButtonType(.pushOnPushOff)
        button2.bezelStyle = .rounded
        button2.state = .off
        
        button3 = NSButton(title: "Component", target: self, action: #selector(buttonGroupTapped(_:)))
        button3.setButtonType(.pushOnPushOff)
        button3.bezelStyle = .rounded
        button3.state = .off

        networkerButton = makeComponentButton(title: ComponentType.networker.buttonTitle)
        computerButton = makeComponentButton(title: ComponentType.computer.buttonTitle)
        printerButton = makeComponentButton(title: ComponentType.printerScannerCopier.buttonTitle)
        screenButton = makeComponentButton(title: ComponentType.screen.buttonTitle)
        networkerButton.state = .on
        
        // 3. Add them to the SpriteKit View
        if let skView = self.view {
            button1.frame = CGRect(x: 20, y: 20, width: 120, height: 32)
            button2.frame = CGRect(x: 150, y: 20, width: 120, height: 32)
            button3.frame = CGRect(x: 280, y: 20, width: 120, height: 32)
            networkerButton.frame = CGRect(x: 410, y: 20, width: 120, height: 32)
            computerButton.frame = CGRect(x: 540, y: 20, width: 120, height: 32)
            printerButton.frame = CGRect(x: 670, y: 20, width: 120, height: 32)
            screenButton.frame = CGRect(x: 800, y: 20, width: 120, height: 32)
            
            skView.addSubview(button1)
            skView.addSubview(button2)
            skView.addSubview(button3)
            skView.addSubview(networkerButton)
            skView.addSubview(computerButton)
            skView.addSubview(printerButton)
            skView.addSubview(screenButton)
        }
    }

    func makeComponentButton(title: String) -> NSButton {
        let button = NSButton(title: title, target: self, action: #selector(componentButtonTapped(_:)))
        button.setButtonType(.pushOnPushOff)
        button.bezelStyle = .rounded
        button.state = .off
        return button
    }

    @objc func componentButtonTapped(_ sender: NSButton) {
        if sender == networkerButton {
            selectedComponentType = .networker
        } else if sender == computerButton {
            selectedComponentType = .computer
        } else if sender == printerButton {
            selectedComponentType = .printerScannerCopier
        } else if sender == screenButton {
            selectedComponentType = .screen
        }

        networkerButton.state = sender == networkerButton ? .on : .off
        computerButton.state = sender == computerButton ? .on : .off
        printerButton.state = sender == printerButton ? .on : .off
        screenButton.state = sender == screenButton ? .on : .off
        buttonGroupTapped(button3)
    }
    
    // 4. Handle the Radio/Latch Logic Manually
    @objc func buttonGroupTapped(_ sender: NSButton) {
        sender.state = .on
        
        if sender == button1 {
            button2.state = .off
            button3.state = .off
            mode(mode: "c")
        } else if sender == button2 {
            button1.state = .off
            button3.state = .off
            mode(mode: "s")
        } else if sender == button3 {
            button1.state = .off
            button2.state = .off
            mode(mode: "b")
        }
    }
    func mode(mode : String!) {
        if mode == "b" {
            print("Component-create mode: \(selectedComponentType.title)")
            widthField.isHidden = true
            restoreDefaultStroke(for: selectedNode)
            restoreDefaultStroke(for: pendingWireStart)
            pendingWireStart = nil
            selectedNode = nil
            isDragging = false
        } else if mode == "s" {
            print("select mode")
            widthField.isHidden = true
            restoreDefaultStroke(for: pendingWireStart)
            pendingWireStart = nil
        } else if mode == "c" {
            print("wire mode")
            widthField.isHidden = true
            restoreDefaultStroke(for: selectedNode)
            selectedNode = nil
            isDragging = false
        }
    }
    func addText(in view: SKView, with event: NSEvent) {
        
    }
}
