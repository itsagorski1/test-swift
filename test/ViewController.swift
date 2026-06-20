//
//  ViewController.swift
//  test
//
//  Created by Jonah Gorski on 6/15/26.
//

import Cocoa
import SpriteKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.skView {
            // Load IntroScene first
            let scene = IntroScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
        }
    }
}

