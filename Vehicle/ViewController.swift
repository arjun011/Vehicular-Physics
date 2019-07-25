//
//  ViewController.swift
//  Floor is Lava
//
//  Created by JiniGuruiOS on 12/07/19.
//  Copyright © 2019 jiniguru. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController {

    @IBOutlet weak var scenView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scenView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.scenView.session.run(self.configuration)
        self.scenView.delegate = self
    
        // Do any additional setup after loading the view.
    }
    
    func createLavaNode(planeAnchor:ARPlaneAnchor) -> SCNNode {
        let lavaNode = SCNNode.init(geometry: SCNPlane.init(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)))
        lavaNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        lavaNode.geometry?.firstMaterial?.isDoubleSided = true
        lavaNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        lavaNode.eulerAngles = SCNVector3.init(90.degreesToRadians, 0, 0)
        return lavaNode
    }
}

extension ViewController:ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planDetection = anchor as? ARPlaneAnchor else {
            return
        }
        let lavaNode = self.createLavaNode(planeAnchor: planDetection)
        node.addChildNode(lavaNode)
        print("Plane Anhor detect")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planDetection = anchor as? ARPlaneAnchor else {
            return
        }
        
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        let lavaNode = self.createLavaNode(planeAnchor: planDetection)
        node.addChildNode(lavaNode)
        
        print("Update Sureface")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {
            return
        }
        
        node.enumerateHierarchy { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}
