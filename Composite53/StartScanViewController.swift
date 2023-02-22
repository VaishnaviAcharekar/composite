//
//  StartScanViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit

class StartScanViewController: Baseviewcontroller {
    
    @IBOutlet weak var scanBtn: UIButton!
    
    @IBOutlet weak var tutorialBtn: UIButton!
    
    @IBOutlet weak var MyScanBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        scanBtn.layer.cornerRadius = 30.0
        scanBtn.backgroundColor = UIColor.lightingPurpleColor
        
        tutorialBtn.layer.cornerRadius = 30.0
        tutorialBtn.backgroundColor = UIColor.lightingPurpleColor
        
        MyScanBtn.layer.cornerRadius = 30.0
        MyScanBtn.backgroundColor = UIColor.lightingPurpleColor
        
        
     
        
        
    }
    
    @IBAction func scanBtn(_ sender: UIButton) {
        
        let vc = LegViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func tutorialBtn(_ sender: UIButton) {
        
        let vc = TutorialViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func myScansBtn(_ sender: UIButton) {
        let vc = PastScanViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
   
}
