//
//  TutorialViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit

class TutorialViewController: Baseviewcontroller {

    
    @IBOutlet weak var hwToScan: UIButton!
    
    @IBOutlet weak var EditScan: UIButton!
    
    @IBOutlet weak var SPRBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        hwToScan.layer.cornerRadius = 30.0
        hwToScan.backgroundColor = UIColor.lightingPurpleColor
        
        EditScan.layer.cornerRadius = 30.0
        EditScan.backgroundColor = UIColor.lightingPurpleColor
        
        SPRBtn.layer.cornerRadius = 30.0
        SPRBtn.backgroundColor = UIColor.lightingPurpleColor
    }
    
    @IBAction func HowToScanBtn(_ sender: UIButton) {
        let vc = HowToScanViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func EditScanBtn(_ sender: UIButton) {
    }
    
    @IBAction func RecordingBtn(_ sender: UIButton) {
    }
    
    @IBAction func BackBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
}
