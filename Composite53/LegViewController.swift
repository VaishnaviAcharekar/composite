//
//  LegViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit

class LegViewController: Baseviewcontroller {

    
    @IBOutlet weak var leftLeg: UIButton!
    
    @IBOutlet weak var rightLeg: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        leftLeg.layer.cornerRadius = 30.0
        leftLeg.backgroundColor = UIColor.lightingPurpleColor
        
        rightLeg.layer.cornerRadius = 30.0
        rightLeg.backgroundColor = UIColor.lightingPurpleColor
    }
    
    @IBAction func legbtn(_ sender: UIButton) {
        let vc = scanningViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func rightLeg(_ sender: UIButton) {
        
        let vc = scanningViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func BackBtn(_ sender: UIButton) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    

}
