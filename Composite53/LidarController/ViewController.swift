///*
//See LICENSE folder for this sample’s licensing information.
//
//Abstract:
//Main view controller for the AR experience.
//*/
//
//import ARKit
//import Combine
//import Metal
//import MetalKit
//import RealityKit
//import simd
//import SwiftUI
//import UIKit
//
//
//final class ViewController: UIViewController, ARSessionDelegate {
//    private let isUIEnabled = true
//    private let confidenceControl = UISegmentedControl(items: ["Low", "Medium", "High"])
//    private let rgbRadiusSlider = UISlider()
//
//    private let session = ARSession()
//    @IBOutlet weak var saveButton: UIButton!
//    private var renderer: Renderer!
//    // MARK: - Properties
//    var trackingStatus: String = ""
//
//    func createSpinnerView() {
//        let child = SpinnerViewController()
//
//        // add the spinner view controller
//        addChild(child)
//        child.view.frame = view.frame
//        view.addSubview(child.view)
//        child.didMove(toParent: self)
//
//        // wait two seconds to simulate some work happening
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            // then remove the spinner view controller
//            child.willMove(toParent: nil)
//            child.view.removeFromSuperview()
//            child.removeFromParent()
//        }
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        guard let device = MTLCreateSystemDefaultDevice() else {
//            print("Metal is not supported on this device")
//            return
//        }
//
//        session.delegate = self
//
//        // Set the view to use the default device
//        if let view = view as? MTKView {
//            view.device = device
//
//            view.backgroundColor = UIColor.clear
//            // we need this to enable depth test
//            view.depthStencilPixelFormat = .depth32Float
//            view.contentScaleFactor = 1
//            view.delegate = self
//
//            // Configure the renderer to draw to the view
//            renderer = Renderer(session: session, metalDevice: device, renderDestination: view)
//            renderer.drawRectResized(size: view.bounds.size)
//        }
//        /*
//        Confidence control
//        confidenceControl.backgroundColor = .white
//        confidenceControl.selectedSegmentIndex = renderer.confidenceThreshold
//        confidenceControl.addTarget(self, action: #selector(viewValueChanged), for: .valueChanged)
//
//        // RGB Radius control
//        rgbRadiusSlider.minimumValue = 0
//        rgbRadiusSlider.maximumValue = 1.5
//        rgbRadiusSlider.isContinuous = true
//        rgbRadiusSlider.value = renderer.rgbRadius
//        rgbRadiusSlider.addTarget(self, action: #selector(viewValueChanged), for: .valueChanged)
//
//        let stackView = UIStackView(arrangedSubviews: [confidenceControl, rgbRadiusSlider])
//        stackView.isHidden = !isUIEnabled
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.axis = .vertical
//        stackView.spacing = 20
//
//        view.addSubview(stackView)
//        NSLayoutConstraint.activate([
//            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
//        ])*/
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        // Create a world-tracking configuration, and
//        // enable the scene depth frame-semantic.
//        let configuration = ARWorldTrackingConfiguration()
//        configuration.frameSemantics = .sceneDepth
//
//        // Run the view's session
//        session.run(configuration)
//
//        // The screen shouldn't dim during AR experiences.
//        UIApplication.shared.isIdleTimerDisabled = true
//    }
//
//    @IBAction func saveButtonAction(_ sender: Any) {
//        print("save action")
//        DispatchQueue.main.async {
//            self.renderer.changeoriginnew()
//            self.renderer.savePointsToFilenew()
//            self.renderer.particleBufferIn()
//            self.renderer.isSavingFile = true
//            self.session.pause()
//
//        let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
//        let secondViewController = mainStoryBoard.instantiateViewController(withIdentifier: "ShowPointCloudViewController") as! ShowPointCloudViewController
//        self.navigationController?.pushViewController(secondViewController, animated: true)
//
//        }
//
//    }
//    @objc
//    private func viewValueChanged(view: UIView) {
//        switch view {
//
//        case confidenceControl:
//            renderer.confidenceThreshold = confidenceControl.selectedSegmentIndex
//
//        case rgbRadiusSlider:
//            renderer.rgbRadius = rgbRadiusSlider.value
//
//        default:
//            break
//        }
//    }
//
//    // Auto-hide the home indicator to maximize immersion in AR experiences.
//    override var prefersHomeIndicatorAutoHidden: Bool {
//        return true
//    }
//
//    // Hide the status bar to maximize immersion in AR experiences.
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
//
//}
//
//// MARK: - MTKViewDelegate
//
//extension ViewController: MTKViewDelegate {
//    // Called whenever view changes orientation or layout is changed
//    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//        renderer.drawRectResized(size: size)
//    }
//
//    // Called whenever the view needs to render
//    func draw(in view: MTKView) {
//        renderer.draw()
//    }
//}
//
//// MARK: - RenderDestinationProvider
//
//protocol RenderDestinationProvider {
//    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
//    var currentDrawable: CAMetalDrawable? { get }
//    var colorPixelFormat: MTLPixelFormat { get set }
//    var depthStencilPixelFormat: MTLPixelFormat { get set }
//    var sampleCount: Int { get set }
//}
//
//extension MTKView: RenderDestinationProvider {
//
//}
//
//// MARK: - AR Session Management (ARSCNViewDelegate)
//
//extension ViewController {
//
//  func initARSession() {
//    guard ARWorldTrackingConfiguration.isSupported else {
//      print("*** ARConfig: AR World Tracking Not Supported")
//      return
//    }
//
//    let config = ARWorldTrackingConfiguration()
//    config.worldAlignment = .gravity
//    config.providesAudioData = false
//    config.isLightEstimationEnabled = true
//    config.environmentTexturing = .automatic
//    session.run(config)
//  }
//
//  func resetARSession() {
//    let config = session.configuration as!
//      ARWorldTrackingConfiguration
//    config.planeDetection = .horizontal
//    session.run(config, options: [.resetTracking, .removeExistingAnchors])
//  }
//
//  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
//    switch camera.trackingState {
//    case .notAvailable:
//      self.trackingStatus = "Tracking:  Not available!"
//    case .normal:
//      self.trackingStatus = ""
//    case .limited(let reason):
//      switch reason {
//      case .excessiveMotion:
//        self.trackingStatus = "Tracking: Limited due to excessive motion!"
//      case .insufficientFeatures:
//        self.trackingStatus = "Tracking: Limited due to insufficient features!"
//      case .relocalizing:
//        self.trackingStatus = "Tracking: Relocalizing..."
//      case .initializing:
//        self.trackingStatus = "Tracking: Initializing..."
//      @unknown default:
//        self.trackingStatus = "Tracking: Unknown..."
//      }
//    }
//  }
//
//
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        // Present an error message to the user.
//        self.trackingStatus = "AR Session Failure: \(error)"
//        guard error is ARError else { return }
//        let errorWithInfo = error as NSError
//        let messages = [
//            errorWithInfo.localizedDescription,
//            errorWithInfo.localizedFailureReason,
//            errorWithInfo.localizedRecoverySuggestion
//        ]
//        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
//        DispatchQueue.main.async {
//            // Present an alert informing about the error that has occurred.
//            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
//            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
//                alertController.dismiss(animated: true, completion: nil)
//                if let configuration = self.session.configuration {
//                    self.session.run(configuration, options: .resetSceneReconstruction)
//                }
//            }
//            alertController.addAction(restartAction)
//            self.present(alertController, animated: true, completion: nil)
//        }
//    }
//
//  func sessionWasInterrupted(_ session: ARSession) {
//    self.trackingStatus = "AR Session Was Interrupted!"
//  }
//
//  func sessionInterruptionEnded(_ session: ARSession) {
//    self.trackingStatus = "AR Session Interruption Ended"
//  }
//}
//// MARK: - Scene Management
//
//extension ViewController {
//  /**
//  func initScene() {
//    let scene = SCNScene()
//    sceneView.scene = scene
//    sceneView.delegate = self
//  }
//
//  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//    DispatchQueue.main.async {
//      self.updateStatus()
//    }
//  }
//
//  func updateStatus() {
//    switch appState {
//    case .DetectSurface:
//      statusMessage = "Scan available flat surfaces..."
//    case .PointAtSurface:
//      statusMessage = "Point at designated surface first!"
//    case .TapToStart:
//      statusMessage = "Tap to start."
//    case .Started:
//      statusMessage = "Tap objects for more info."
//    }
//
//    self.statusLabel.text = trackingStatus != "" ?
//      "\(trackingStatus)" : "\(statusMessage)"
//  } **/
//}
//
//// MARK: - Focus Node Management
//
