//
//  ShowPastScanViewController.swift
//  Composite53
//
//  Created by user on 21/02/23.
//

import UIKit
import SceneKit
import ARKit

class ShowPastScanViewController: UIViewController ,  ARSCNViewDelegate{

    var url : URL!
    
    @IBOutlet weak var scenekit: SCNView!
    var pointsWithArms1: [SCNVector3] = [SCNVector3]()
    var ship: SCNNode = SCNNode(geometry: SCNTube(innerRadius: 0.06, outerRadius: 0.1, height: 1))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        // Do any additional setup after loading the view.
       
        
        print("filepath", url)
        
        if FileManager.default.fileExists(atPath: url.path) {
            print("file exist", url.path)
                    // read the file data
                    guard let data = try? Data(contentsOf: url) else { return }
            
            self.pointsWithArms1 = StaticAlgos.LoadPointsFromFile(path: url.path)
            print("file exist with points", pointsWithArms1.count)
            self.InitialiseNodesInScnScene()
                    
//                     print("data", data)
//                    // create a scene from the file data
//                    let scene = SCNScene()
//
//                    let pointCloud = SCNGeometry.pointCloudFromPCD(data: data)
//                    let node = SCNNode(geometry: pointCloud)
//                    scene.rootNode.addChildNode(node)
//
//                    // display the scene
//                    scenekit.scene = scene
//                    scenekit.backgroundColor = .white
//                  self.scenekit.autoenablesDefaultLighting = true
//                self.scenekit.showsStatistics = false
//                 scenekit.pointOfView?.camera?.zNear = 0.01
//                scenekit.pointOfView?.camera?.zFar = 1000
//               scenekit.pointOfView?.camera?.orthographicScale = 0.5
            
            
            
                } else {
                    print("File does not exist")
                }
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func InitialiseNodesInScnScene()
    {
        //Debugger.show(type: DebugType.log, log: " called")
        
        DispatchQueue.main.async { [self] in
            let scene = SCNScene()
            self.scenekit.scene = scene
            scenekit.backgroundColor = UIColor.white
            // Set scene settings
//            ScenekitView.scene = scene
            let camera = SCNCamera()
            camera.usesOrthographicProjection = true
            camera.orthographicScale = 0.7
            camera.zNear = 0
            camera.zFar = 100 // try different values of zFar when in orthographic
            
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            scene.rootNode.addChildNode(cameraNode)
            cameraNode.position = SCNVector3(x: 0, y: 0, z: 0.25)
            self.scenekit.allowsCameraControl = true
            self.scenekit.defaultCameraController.maximumVerticalAngle = 0.001
            
            let validPointCloud = PointCloud()
            validPointCloud.loadPointCloudPCD(pointsWithArms1)
            print("validpoints", validPointCloud.pointCloud.count)

            
            let CombinedPointCloud = PointCloud()
            CombinedPointCloud.pointCloud.append(contentsOf: validPointCloud.pointCloud)
//            CombinedPointCloud.pointCloud.append(contentsOf: invalidPointCloud.pointCloud)
            let cloud = CombinedPointCloud.getNode(useColor: true)
            
            cloud.name = "cloud"
            scene.rootNode.addChildNode(cloud)
            self.ship = scene.rootNode.childNode(withName: "cloud", recursively: true)!
           
            self.ship.position = SCNVector3(x: 0, y: 0, z: -0.5)
            self.ship.eulerAngles = SCNVector3Make(0, Float.pi / 2, 0)
            
          
            
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light!.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 0, z: 0)
            scene.rootNode.addChildNode(lightNode)
            
            // create and add an ambient light to the scene
            let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light!.type = .ambient
            ambientLightNode.light!.color = UIColor(red: 255.0 / 255.0, green: 255.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)
            ambientLightNode.position = SCNVector3(x: 0, y: 0, z: 0)
            scene.rootNode.addChildNode(ambientLightNode)
            
           
            
            self.scenekit.autoenablesDefaultLighting = true
            self.scenekit.showsStatistics = false
            scenekit.pointOfView?.camera?.zNear = 0.01
            scenekit.pointOfView?.camera?.zFar = 1000
            scenekit.pointOfView?.camera?.orthographicScale = 0.5
          
           
        }
    }
    
    static func LoadPointsFromFile(path _path: String, reverseZ _reverseZ: Bool = false) -> [SCNVector3]
    {
        var array = [SCNVector3]()
        let filePath = _path.deletingFilePrefix()
        
        if !FileManager.default.fileExists(atPath: filePath)
        {
            print("invalid path", filePath)
//            Debugger.show(type: DebugType.log, val: "invalid path", log: filePath)
            return array
        }
        
        let contents = try! String(contentsOfFile: filePath)
        // Split the file into separate lines
        let lines = contents.split(separator:"\r\n")
        
        //        if lines.count < 10
        //        {
        //            lines = contents.split(separator: "\n")
        //        }
        
        // Iterate over each line and print the line
        var i = 0
        for line in lines
        {
            if (i > 10)
            {
                let line11 = String(line)
                let bbb = line11.components(separatedBy: " ")
                let x = Float(bbb[1])!
                let y = Float(bbb[2])!
                var z = Float(bbb[3])!
                if _reverseZ
                {
                    z *= -1
                }
                array.append(SCNVector3(x: x, y: y, z: z))
            }
            i += 1
        }
        
        return array
    }

}

extension SCNGeometry {
    static func pointCloudFromPCD(data: Data) -> SCNGeometry {
        // parse the PCD file format
        // see http://pointclouds.org/documentation/tutorials/pcd_file_format.php
        
        let scanner = Scanner(string: String(data: data, encoding: .utf8)!)
        
        // read header
        scanner.scanUpTo("POINTS", into: nil)
        scanner.scanString("POINTS", into: nil)
        var pointsCount = 0
        scanner.scanInt(&pointsCount)
        scanner.scanUpTo("DATA", into: nil)
        scanner.scanString("DATA", into: nil)
        scanner.scanUpTo("\n", into: nil)
        
        // read points
        var points = [SCNVector3]()
        for _ in 0..<pointsCount {
            var x = Float(0.0)
            var y = Float(0.0)
            var z = Float(0.0)
            scanner.scanFloat(&x)
            scanner.scanFloat(&y)
            scanner.scanFloat(&z)
            points.append(SCNVector3(x, y, z))
        }
        
        // create point cloud geometry
        let source = SCNGeometrySource(vertices: points)
        let element = SCNGeometryElement(indices: Array(0..<pointsCount), primitiveType: .point)
        return SCNGeometry(sources: [source], elements: [element])
    }
}




