//
//  AvtarViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit
import SceneKit
import ARKit



enum AppState: Int16 {
  case DetectSurface  // Scan surface (Plane Detection On)
  case PointAtSurface // Point at surface to see focus point (Plane Detection Off)
  case TapToStart     // Focus point visible on surface, tap to start
  case Started
}

var myscans : [URL] = []
var myscansname : [String] = []
var myscansdate : [Date] = []
var count = 0

class AvtarViewController: Baseviewcontroller, ARSCNViewDelegate {

    var focusPoint:CGPoint!
    var focusNode: SCNNode!
    var arPortNode: SCNNode!
//    var ship : SCNNode = SCNNode(geometry: SCNTube(innerRadius: 3.0, outerRadius: 3.0, height: 45))
    var trackingStatus: String = ""
    var statusMessage: String = ""
    var appState: AppState = .DetectSurface
    var completepath : String = ""
    var path : String = ""
    private var currentPointCount = 0
    @IBOutlet weak var ScenekitView: SCNView!
    var renderer: Renderer!
    
    var isSavingFile = true {
        didSet {
            print("isSavingFile:\(isSavingFile)")
        }
    }
   
    var ship: SCNNode = SCNNode(geometry: SCNTube(innerRadius: 0.06, outerRadius: 0.1, height: 1))
//    @IBAction func tapGestureHandler(_ sender: Any) {
//      guard appState == .TapToStart else { return }
//      self.arPortNode.isHidden = false
//      self.focusNode.isHidden = true
//      self.arPortNode.position = self.focusNode.position
//      appState = .Started
//    }
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.

        
//          NotificationCenter.default.addObserver(self, selector: #selector(self.updateStatus), name: Notification.Name("reloadviewscnuploaded"), object: nil)
//
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.CustomPinchGesture))
        ScenekitView.addGestureRecognizer(pinchRecognizer)
        
//        let panGestureRecogniser = UIPanGestureRecognizer(target: self, action: #selector(self.CustomPanGesture))
//        ScenekitView.addGestureRecognizer(panGestureRecogniser)
//
//        let rotateGestureRecogniser = UIRotationGestureRecognizer(target: self, action: #selector(self.CustomRotateGesture))
        
       
        
        self.InitialiseNodesInScnScene()
        
    }
    
    
  
    
    @IBAction func BackBtn(_ sender: UIButton) {
        self.popTo(withScreen: StartScanViewController.self)
    }
    
    
    @IBAction func EraseBtn(_ sender: UIButton) {
    }
    
    
    @IBAction func UndoBtn(_ sender: UIButton) {
    }
    
    @IBAction func SaveBtn(_ sender: UIButton) {
        
//        myscans.append(filepathURL)
//        count += 1
//        myscansname.append("scans #\(count)")
//
//        let date = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "YYYY/MM/dd"
//        myscansdate.append( dateFormatter.string(from: date))
//
//        print("data:", myscans, myscansname, myscansdate, count)
        showLoader()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.saveFileToPCD()
            
            // Create a UIAlertController to display the message
            let alertController = UIAlertController(title: "Done", message: "You can show your scans in My scns section.", preferredStyle: .alert)
            
            // Add an "OK" button to dismiss the alert
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                // Handle the "OK" button tap if needed
                self.popToVC(withVC: StartScanViewController.self)
            }
            alertController.addAction(okAction)
            
            // Display the alert controller
            self.present(alertController, animated: true, completion: nil)
            hideLoader()
        }

          
        
    }
    
    @objc func InitialiseNodesInScnScene()
    {
        //Debugger.show(type: DebugType.log, log: " called")
        
        DispatchQueue.main.async { [self] in
            let scene = SCNScene()
            self.ScenekitView.scene = scene
            ScenekitView.backgroundColor = UIColor.white
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
            self.ScenekitView.allowsCameraControl = true
            self.ScenekitView.defaultCameraController.maximumVerticalAngle = 0.001
            
            let validPointCloud = PointCloud()
            validPointCloud.loadPointCloudPCD(pointsWithArms)
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
            
           
            
            self.ScenekitView.autoenablesDefaultLighting = true
            self.ScenekitView.showsStatistics = false
            ScenekitView.pointOfView?.camera?.zNear = 0.01
            ScenekitView.pointOfView?.camera?.zFar = 1000
            ScenekitView.pointOfView?.camera?.orthographicScale = 0.5
          
           
        }
    }
    
    
    func saveFileToPCD(){
        
        print("points in points ", pointsWithArms.count)
        
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd_HHmmss"
//        let PCD_Folder_Name = dateFormatter.string(from: date)
        
        let docURL = GetDocumentDirectoryUrl()
        let dataPath = docURL.appendingPathComponent("Scans")
        
        if !FileManager.default.fileExists(atPath: dataPath.path)
        {
            do
            {
                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch
            {
                print("Cannot create a directory")
//                Debugger.show(type: DebugType.log, val: "Cannot create a directory", log: error.localizedDescription)
            }
        }
        
        var pathToRawPcd: String
//        var pathToRawPcdWithoutArms: String
//        var pathToNrmPcdWithArms: String
//        var pathToNrmPcdWithoutArms: String
        
        let saveScanFolder = dataPath.absoluteString + "/"
        
        //let appName = CustomerSession.Instance.AppName
        pathToRawPcd =  saveScanFolder + "scans_\(dateFormatter.string(from: date)).pcd"
        print("filepathURL1", pathToRawPcd)
        
        var finalPointsPCD = [SCNVector3]()
        finalPointsPCD = pointsWithArms
        
        for i in stride(from: 0, to: finalPointsPCD.count, by: 1)
        {
            finalPointsPCD[i].z *= -1
        }
       
        
        let rawWithPoints = StaticAlgos.RemoveNoisyPoints(finalPointsPCD)
        savePointsToDirectory(rawWithPoints, pathToRawPcd)
        
    }
    
    func savePointsToDirectory(_ points: [SCNVector3], _ _filepath: String)
    {
        var filePath = ""
        if _filepath.hasPrefix("file://")
        {
            filePath = _filepath
        }
        else
        {
            filePath = "file://" + _filepath
        }
        let count = points.count
        var fileToWritecolor = ""
        let headerscolor =
        [
            "VERSION .7",
            "FIELDS x y z",
            "SIZE 4 4 4",
            "TYPE F F F",
            "COUNT 1 1 1",
            "WIDTH \(count)",
            "HEIGHT 1",
            "VIEWPOINT 0 0 0 1 0 0 0",
            "POINTS \(count)",
            "DATA ascii"
        ]
        
        for header in headerscolor
        {
            fileToWritecolor += header
            fileToWritecolor += "\r\n"
        }
        
        for i in stride(from: 0, to: count, by: 1)
        {
            let point = points[i]
            let pvValue = " \(point.x) \(point.y) \(point.z)"
            fileToWritecolor += pvValue
            fileToWritecolor += "\r\n"
        }
        
        do
        {
            filepathURL = URL(string: filePath)!
            print("filepathURL", filepathURL)
            try fileToWritecolor.write(to: filepathURL, atomically: true, encoding: String.Encoding.ascii)
        }
        catch
        {
            print("error in saving at",  "\(filePath)")
//            Debugger.show(type: DebugType.log, val: "error in saving at", log: "\(filePath)")
        }
    }
    
    
    @objc func CustomPinchGesture(_ gesture: UIPinchGestureRecognizer)
    {
        if gesture.state == .changed
        {
            var view = ScenekitView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            if view.a >= 1.4//1.6
            {
                view.a = 1.4//1.6
                view.d = 1.4//1.6
            }
            else if view.a <= 0.8//0.48
            {
                view.a = 0.8//0.48
                view.d = 0.8//0.48
            }
            ScenekitView.transform = view
            gesture.scale = 1.0
        }
        
        if gesture.state == .ended
        {
            if ScenekitView.transform.a > 1.4//1.6
            {
                ScenekitView.transform.a = 1.4//1.6
                ScenekitView.transform.d = 1.4//1.6
            }
            else if ScenekitView.transform.a < 0.8//0.48
            {
                ScenekitView.transform.a = 0.8//0.48
                ScenekitView.transform.d = 0.8//0.48
            }
        }
    }
    
    
}

extension AvtarViewController {
  
  func initScene() {
    let scene = SCNScene()
    sceneView.scene = scene
    sceneView.delegate = self
    //sceneView.showsStatistics = true
    sceneView.debugOptions = [
      //ARSCNDebugOptions.showFeaturePoints,
      //ARSCNDebugOptions.showWorldOrigin,
      //SCNDebugOptions.showBoundingBoxes,
      //SCNDebugOptions.showWireframe
    ]
    
    let arPortScene = SCNScene(named: "art.scnassets/Scenes/ARPortScene.scn")!
    arPortNode = arPortScene.rootNode.childNode(
      withName: "ARPort", recursively: false)!
    arPortNode.isHidden = true
    sceneView.scene.rootNode.addChildNode(arPortNode)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    DispatchQueue.main.async {
        self.updateStatus()
        print("called")
    }
  }
    @objc internal  func  updateStatus(){
        print("call update status")
      
        do {
       
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let fileManager = FileManager.default
           
        // var pathname =  Helper().retrievePathnameFromKeychain() ?? "ply_sancfile.scn"
            var  pathname =  Helper().retrievePathnameFromKeychain() ?? "ply_sancfile.scn"
            print("completepathname: ", Helper().retrievePathnameFromKeychain() )
         completepath = Helper().retrievePathnameFromKeychain() ?? "/var/mobile/Containers/Data/Application/36569A96-F982-4023-A826-D2288FE9CC9B/Documents/"
         path = completepath.deletingPrefix("/var/mobile/Containers/Data/Application/36569A96-F982-4023-A826-D2288FE9CC9B/Documents/")
       
        let imagePAth = (documentsDirectory as NSString).appendingPathComponent(completepath)
            Logger.shared().log(message: "name of file \(pathname) image path \(imagePAth)")
            print("imagePAth:\(imagePAth)")
        if fileManager.fileExists(atPath: imagePAth){
           
            print("imagePAth:\(imagePAth)")
            let myURL = URL(fileURLWithPath : imagePAth)
            let scene = try SCNScene(url: myURL as URL, options: nil)
             //setup the camera
//        let scene = SCNScene(named: "ply_color.scn")!
            let camera = SCNCamera();
            camera.usesOrthographicProjection = true
            camera.orthographicScale = 1
            camera.zNear = 0
            camera.zFar = 100;
            // create and add a camera to the scene
            let cameraNode = SCNNode()
            cameraNode.camera = camera
            scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0.5)
        // cameraNode.eulerAngles = SCNVector3Make(180, 0, 180)
            // place the camera
            //cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
            
//        let box = SCNBox(width: 0.2, height: 0.2, length: 10, chamferRadius: 5);
//                    let boxNode = SCNNode(geometry: box)
//                    scene.rootNode.addChildNode(boxNode)
        //boxNode.position = SCNVector3(x: 0, y: 0, z: -5)
//        let rod = SCNTube(innerRadius: 0.06, outerRadius: 0.1, height: 5)
//        let rodnode = SCNNode(geometry: rod)
//        scene.rootNode.addChildNode(rodnode)
//        rodnode.position = SCNVector3(x: 0, y: 0, z: -0.3)
//        rodnode.eulerAngles = SCNVector3Make(90, 0, 20);
            //        // retrieve the ship node
//             ship = scene.rootNode.childNode(withName: "cloud", recursively: true)!
           // scene.rootNode.addChildNode(ship)
//             ship.position = SCNVector3(x: 0, y: 0, z: 0)
//         ship.eulerAngles = SCNVector3Make(0, 0, 0)
         //tube = scene.rootNode.childNode(withName: "tube", recursively: true)!
//        let tubes = SCNTube(innerRadius: 0.06, outerRadius: 0.1, height: 5)
//        let tubesnode = SCNNode(geometry: tubes)
//       // scene.rootNode.addChildNode(tubesnode)
//        tubesnode.position = SCNVector3(x: 0, y: 0, z: 0.23)
//        // tubesnode.c
//           //  newAngleY * ( 180 / Double.pi)
//        tubesnode.eulerAngles = SCNVector3Make(0, 0, 0)
//        print("position of tube node \(tubesnode.position)")
        //tube.rotation = SCNVector4(x: 0, y: 1, z: 1, w: 45)
            // put a constraint on the camera1
//            let constraint = SCNLookAtConstraint(target: ship)
            
//            cameraNode.constraints = [constraint]
            //        let targetNode = SCNLookAtConstraint(target: ship);
            //        //targetNode.gimbalLockEnabled = YES;
            //        cameraNode.constraints = [targetNode];
            
            // create and add a light to the scene
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light!.type = .omni
            lightNode.position = SCNVector3(x: 0, y: 0, z: 0)
            scene.rootNode.addChildNode(lightNode)
            
            // create and add an ambient light to the scene
            let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light!.type = .ambient
            ambientLightNode.light!.color = UIColor.darkGray
            ambientLightNode.position = SCNVector3(x: 0, y: 0, z: 0)
            scene.rootNode.addChildNode(ambientLightNode)
            
            
            
            
            // animate the 3d object
            //ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
            
            // retrieve the SCNView
            //let scnView = SCNView()
            
            
            
            // put a constraint on the camera
            //        let cameraOrbit = SCNNode()
            //        cameraOrbit.addChildNode(cameraNode)
            //        scene.rootNode.addChildNode(cameraOrbit)
            //
            //        // rotate it (I've left out some animation code here to show just the rotation)
            //        cameraOrbit.eulerAngles.x -= Float(CGFloat(M_PI_4))
            //        cameraOrbit.eulerAngles.y -= Float(CGFloat(M_PI_4*3))
            // Allow user to manipulate camera
            ScenekitView.allowsCameraControl = true

            // Show FPS logs and timming
            // sceneView.showsStatistics = true

            // Set background color
//            ScenekitView.backgroundColor = UIColor.white

            // Allow user translate image
            ScenekitView.autoenablesDefaultLighting = true
            ScenekitView.cameraControlConfiguration.allowsTranslation = false
            // ScenekitView.backgroundColor = UIColor(red: 41, green: 42, blue: 51, alpha: 1.0)
            
            
            ScenekitView.backgroundColor = UIColor.white
            // Set scene settings
            ScenekitView.scene = scene
        
            ScenekitView.defaultCameraController.maximumVerticalAngle = 0.001
           
//                SCNTransaction.begin()
//                SCNTransaction.animationDuration = 5
//                scnView.defaultCameraController.translateInCameraSpaceBy(x: 10, y: 10, z: 10)
//                SCNTransaction.commit()
            
           
            
          
            
            // show statistics such as fps and timing information
            ScenekitView.showsStatistics = false
            
            // configure the view
//            ScenekitView.backgroundColor = UIColor.white
            
            // Allow user translate image
            ScenekitView.cameraControlConfiguration.allowsTranslation = false
            
            // scnView.cameraControlConfiguration.rotationSensitivity = true
            let cameraNodes = ScenekitView.pointOfView
            print("cameraNodes:\(cameraNodes)")
            

        } else{
            print("No Image")
        }
        } catch {
            print("error")
            let scnView = SCNView()
        }

    }
}
