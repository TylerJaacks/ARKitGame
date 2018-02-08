//
//  Spaceship.swift
//  ARKitGame
//
//  Created by Tyler Jaacks on 7/1/17.
//  Copyright © 2017 Tyler Jaacks. All rights reserved.
//

import UIKit
import SceneKit

class Spaceship: SCNNode {
    func loadModel() {
        guard let virtualObjectScene = SCNScene(named: "Art.scnassets/Ship.scn") else {
            return
        }
        
        let wrapperNode = SCNNode()
        
        for child in virtualObjectScene.rootNode.childNodes {
            wrapperNode.addChildNode(child)
        }
        
        self.addChildNode(wrapperNode)
    }
}
