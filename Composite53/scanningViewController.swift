//
//  scanningViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import ARKit
import Combine
import Metal
import MetalKit
import RealityKit
import simd
import SwiftUI
import UIKit

class scanningViewController: Baseviewcontroller ,ARSessionDelegate{
   
    @IBOutlet weak var sceneView: ARSCNView!
    private var session = ARSession()
    private let confidenceControl = UISegmentedControl(items: ["Low", "Medium", "High"])
    private let rgbRadiusSlider = UISlider()
    var time1 = Timer()
    var counter: Int = 0
    @IBOutlet weak var ScnView: MTKView!
    private var renderer: Renderer!
    var trackingStatus : String = ""
    static var isCountingComplete: Bool = false
    var crossButtonFix: Bool = true
    @IBOutlet weak var countDownLabel: UILabel!
    var configuration = ARWorldTrackingConfiguration()
    var sessiongetsstarted: Bool = false
    var firstcome: Bool = false
    
    func createSpinnerView() {
        let child = SpinnerViewController()

        // add the spinner view controller
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)

        // wait two seconds to simulate some work happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // then remove the spinner view controller
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.countDownLabel.isHidden = true
        self.crossButtonFix = true
      
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        self.configuration = ARWorldTrackingConfiguration()
        self.session = ARSession()
        session.delegate = self
       
        
        // Set the view to use the default device
//        if let view = view as? MTKView {
        ScnView.device = device
            
        ScnView.backgroundColor = UIColor.clear
            // we need this to enable depth test
        ScnView.depthStencilPixelFormat = .depth32Float
        ScnView.contentScaleFactor = 1
        ScnView.delegate = self
        
        renderer = Renderer(session: session, metalDevice: device, renderDestination: ScnView)
        renderer.drawRectResized(size: view.bounds.size)
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
       
        self.session.run(self.configuration)

       
//        session.run(configuration)
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
     
    }
    
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        print("update", session.currentFrame)
////        draw(in: ScnView)
//    }
//
    
    @objc
    private func viewValueChanged(view: UIView) {
        switch view {
            
        case confidenceControl:
            renderer.confidenceThreshold = confidenceControl.selectedSegmentIndex

        case rgbRadiusSlider:
            renderer.rgbRadius = rgbRadiusSlider.value
            
        default:
            break
        }
    }
    
    @objc func updateCounter()
    {
        
        if crossButtonFix == true
        {
            if counter > 0
            {
                
                counter -= 1
                print("counter", counter)
            }
            
            switch counter
            {
                case 1:
                    //ProcessDeepLinkMgr.Instance?.activeDeepLink = false
                    self.countDownLabel.text = "1"
                  
                    print("counter2", counter)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.configuration.frameSemantics = [.sceneDepth, .personSegmentation]
                    self.session.run(self.configuration, options: [ .removeExistingAnchors, .resetSceneReconstruction])
                    scanningViewController.isCountingComplete = true
                    self.sessiongetsstarted = true
                    self.countDownLabel.isHidden = true
                    self.firstcome = true
                }
                    break
                    
                case 2:
                    self.countDownLabel.text = "2"
                    print("counter3", counter)
                    break
                    
                case 3:
                    break
                    
                default:
                    time1.invalidate()
                    //ProcessDeepLinkMgr.Instance?.activeDeepLink = true
                    break
            }
        }
    }
    
    @IBAction func PlayBtn(_ sender: UIButton) {
        
        if !sessiongetsstarted{
            print("counter1", counter)
            counter = 3
            
            self.countDownLabel.text = String(counter)
            self.countDownLabel.isHidden = false
            time1 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
        }
        
      
    }
    
    @IBAction func PauseBtn(_ sender: UIButton) {
        if sessiongetsstarted{
            self.sessiongetsstarted = false
            self.session.pause()
        }                       
    }
    
    @IBAction func stopBtn(_ sender: UIButton) {
        showLoader()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scanningViewController.isCountingComplete = false
            self.renderer.savePointsPCDFormat()
//            self.renderer.changeoriginnew()
//            self.renderer.savePointsToFilenew()
//            self.renderer.particleBufferIn()
            self.renderer.isSavingFile = true
            
            let mainStoryBoard = UIStoryboard(name: "Main", bundle: nil)
            let secondViewController = mainStoryBoard.instantiateViewController(withIdentifier: "AvtarViewController") as! AvtarViewController
            self.navigationController?.pushViewController(secondViewController, animated: true)
            self.session.pause()
            self.renderer.session.pause()
            hideLoader()
//            self.sceneView.removeFromSuperview()


        }
        
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        scanningViewController.isCountingComplete = false
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
}

extension scanningViewController: MTKViewDelegate {
    // Called whenever view changes orientation or layout is changed
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if scanningViewController.isCountingComplete == true
        {
            renderer.drawRectResized(size: size)
        }
        
    }
    
    // Called whenever the view needs to render
    func draw(in view: MTKView) {
        renderer.draw()
    }
}

protocol RenderDestinationProvider {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: CAMetalDrawable? { get }
    var colorPixelFormat: MTLPixelFormat { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var sampleCount: Int { get set }
}

extension MTKView: RenderDestinationProvider {
    
    
}

extension scanningViewController {
    
  func initARSession() {
    guard ARWorldTrackingConfiguration.isSupported else {
      print("*** ARConfig: AR World Tracking Not Supported")
      return
    }
    
    let config = ARWorldTrackingConfiguration()
    config.worldAlignment = .gravity
    config.providesAudioData = false
    config.isLightEstimationEnabled = true
    config.environmentTexturing = .automatic
    session.run(config)
  }
  
  func resetARSession() {
    let config = session.configuration as!
      ARWorldTrackingConfiguration
    config.planeDetection = .horizontal
    session.run(config, options: [.resetTracking, .removeExistingAnchors])
  }
  
  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    switch camera.trackingState {
    case .notAvailable:
      self.trackingStatus = "Tracking:  Not available!"
    case .normal:
      self.trackingStatus = "Tracking:  running normal"
    case .limited(let reason):
      switch reason {
      case .excessiveMotion:
        self.trackingStatus = "Tracking: Limited due to excessive motion!"
      case .insufficientFeatures:
        self.trackingStatus = "Tracking: Limited due to insufficient features!"
      case .relocalizing:
        self.trackingStatus = "Tracking: Relocalizing..."
      case .initializing:
        self.trackingStatus = "Tracking: Initializing..."
      @unknown default:
        self.trackingStatus = "Tracking: Unknown..."
      }
    }
      
      print("tracking status", self.trackingStatus)
  }
  

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        self.trackingStatus = "AR Session Failure: \(error)"
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                if let configuration = self.session.configuration {
                    self.session.run(configuration, options: .resetSceneReconstruction)
                }
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

  func sessionWasInterrupted(_ session: ARSession) {
    self.trackingStatus = "AR Session Was Interrupted!"
  }

  func sessionInterruptionEnded(_ session: ARSession) {
    self.trackingStatus = "AR Session Interruption Ended"
  }
}
