//
//  ViewController.swift
//  Floor is Lava
//
//  Created by JiniGuruiOS on 12/07/19.
//  Copyright © 2019 jiniguru. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion
class ViewController: UIViewController {
    
    @IBOutlet weak var scenView: ARSCNView!
    let motationManager = CMMotionManager()
    let configuration = ARWorldTrackingConfiguration()
    var vehicle = SCNPhysicsVehicle()
    var oritation:CGFloat = 0
    var touchedScreen:Int = 0
    var accelerationValues = [UIAccelerationValue(0),UIAccelerationValue(0)]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scenView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        self.scenView.session.run(self.configuration)
        self.scenView.delegate = self
        self.scenView.showsStatistics = true
        self.setupAccelometer()
    
        // Do any additional setup after loading the view.
    }
    
    func createConcrete(planeAnchor:ARPlaneAnchor) -> SCNNode {
        let concreteNode = SCNNode.init(geometry: SCNPlane.init(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)))
        concreteNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.position = SCNVector3(planeAnchor.center.x,planeAnchor.center.y,planeAnchor.center.z)
        concreteNode.eulerAngles = SCNVector3.init(90.degreesToRadians, 0, 0)
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody
        return concreteNode
    }
    
    @IBAction func btnAddCarSelected(_ sender: Any) {
        
        // Find Current position of camera
        
        guard let pointView = self.scenView.pointOfView else {
            return
        }
        
        let transformMetrix = pointView.transform
        let oritation = SCNVector3(-transformMetrix.m31,-transformMetrix.m32,-transformMetrix.m33)
        let location = SCNVector3(transformMetrix.m41,transformMetrix.m42,transformMetrix.m43)
        
        let currentPositionOfCamera = oritation + location
        
        let carScene = SCNScene.init(named: "carScene.scn")
        let frame = (carScene?.rootNode.childNode(withName: "Frame", recursively: false))!

        let frontRight = frame.childNode(withName: "frontRightParent", recursively: false)
        let frontLeft  = frame.childNode(withName: "frontLeftParent", recursively: false)
        let rearRight  = frame.childNode(withName: "rearRightParent", recursively: false)
        let rearLeft   = frame.childNode(withName: "rearLeftParent", recursively: false)
        
        let v_frontRightWheel = SCNPhysicsVehicleWheel(node: frontRight!)
        let v_frontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeft!)
        let v_rearRightWheel = SCNPhysicsVehicleWheel(node: rearRight!)
        let v_rearLeftWheel  = SCNPhysicsVehicleWheel(node: rearLeft!)
        
        
        frame.position = currentPositionOfCamera
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: frame, options: [SCNPhysicsShape.Option.keepAsCompound : true]))
        frame.physicsBody = body
       // body.mass = 5
        self.vehicle = SCNPhysicsVehicle(chassisBody: frame.physicsBody!, wheels: [v_rearRightWheel,v_rearLeftWheel,v_frontRightWheel,v_frontLeftWheel])
        self.scenView.scene.physicsWorld.addBehavior(self.vehicle)
        self.scenView.scene.rootNode.addChildNode(frame)
    }
    
    func setupAccelometer() {
        if self.motationManager.isAccelerometerAvailable {
           self.motationManager.accelerometerUpdateInterval = 1/60
            self.motationManager.startAccelerometerUpdates(to: .main) { (accelerometerData, error) in
                if error != nil {
                    print("Error accelerometer",error?.localizedDescription ?? "unknown")
                    return
                }
              self.readAccelometerData(accelerometer: accelerometerData!)
            }
        }else {
            print("Accelerometer not availabe")
        }
    }
    
    func readAccelometerData(accelerometer:CMAccelerometerData) {
        
        self.accelerationValues[1] = self.filtered(previousAcceleration: self.accelerationValues[1], UpdatedAcceleration: accelerometer.acceleration.y)
        
          self.accelerationValues[0] = self.filtered(previousAcceleration: self.accelerationValues[0], UpdatedAcceleration: accelerometer.acceleration.x)
        
        if self.accelerationValues[0] > 0 {
            self.oritation = -CGFloat(self.accelerationValues[1] )
        }else {
            self.oritation = CGFloat(self.accelerationValues[1] )
        }
     }
    func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {

        var enginForce:CGFloat = 0
        var brakingForce:CGFloat = 0
        
        self.vehicle.setSteeringAngle(self.oritation, forWheelAt: 2)
        self.vehicle.setSteeringAngle(self.oritation, forWheelAt: 3)
        
        if self.touchedScreen == 1 {
            enginForce = 5
        }else if self.touchedScreen == 2{
            enginForce = -5
        }else if self.touchedScreen == 3 {
            brakingForce = 1000
        }
        
        self.vehicle.applyEngineForce(enginForce, forWheelAt: 0)
        self.vehicle.applyEngineForce(enginForce, forWheelAt: 1)
        self.vehicle.applyBrakingForce(brakingForce, forWheelAt: 2)
        self.vehicle.applyBrakingForce(brakingForce, forWheelAt: 3)
    }
}

extension ViewController:ARSCNViewDelegate {
    
  /*  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            
            guard let transformMatrix = self.scenView.pointOfView else {
                return
            }
            let tarnsform = transformMatrix.transform
            let oritiention = SCNVector3.init(-tarnsform.m31, -tarnsform.m32, -tarnsform.m33)
            let position = SCNVector3(tarnsform.m41,tarnsform.m42,tarnsform.m43)
            let currentPosition = oritiention + position
            
            let currentPointNode = SCNNode.init(geometry: SCNBox.init(width: 0.07, height: 0.07, length: 0.07, chamferRadius: 0))
            currentPointNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            currentPointNode.position = currentPosition
            currentPointNode.name = "Pointer"
            
            self.scenView.scene.rootNode.enumerateChildNodes({ (node, _) in
                if node.name == "Pointer" {
                    node.removeFromParentNode()
                }
            })
            self.scenView.scene.rootNode.addChildNode(currentPointNode)
        }
    } */
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planDetection = anchor as? ARPlaneAnchor else {
            return
        }
        let concreteNode = self.createConcrete(planeAnchor: planDetection)
        node.addChildNode(concreteNode)
        print("Plane Anhor detect")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planDetection = anchor as? ARPlaneAnchor else {
            return
        }
        
        node.enumerateChildNodes { (childNode, _) in
            childNode.removeFromParentNode()
        }
        
        let lavaNode = self.createConcrete(planeAnchor: planDetection)
        node.addChildNode(lavaNode)

    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let _ = anchor as? ARPlaneAnchor else {
            return
        }
        
        node.enumerateHierarchy { (childNode, _) in
            childNode.removeFromParentNode()
        }
    }
    
    func filtered(previousAcceleration: Double, UpdatedAcceleration: Double) -> Double {
        let kfilteringFactor = 0.5
        return UpdatedAcceleration * kfilteringFactor + previousAcceleration * (1-kfilteringFactor)
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

func +(lhs:SCNVector3, rhs:SCNVector3) -> SCNVector3 {
    return SCNVector3Make(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}

//MARK: - Touch sceen -
extension ViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else {
            return
        }
        self.touchedScreen = touches.count
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchedScreen = 0
    }
}
