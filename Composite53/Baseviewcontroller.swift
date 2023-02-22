//
//  Baseviewcontroller.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import Foundation
import UIKit


class Baseviewcontroller: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        self.dosetupUi()
        self.dosetupBtn()
        
        
    }
    
    
    func dosetupUi(){
        
        let imgview = UIImageView(frame: CGRect(x: 10, y: 60, width: 80, height: 50))
        imgview.image = UIImage(named: "logo-no-background 2")
        
        view.addSubview(imgview)
        
        
    }
    
    
    func dosetupBtn(){
        
        let profileBtn = UIButton(type: .custom)
        profileBtn.frame = CGRect(x: 330, y: 60, width: 52, height: 52)
        profileBtn.setImage(UIImage(named: "Rectangle 13"), for: .normal)
        profileBtn.addTarget(self, action: #selector( OpenProfile), for: .touchUpInside)
        view.addSubview(profileBtn)
        
    }
    
    
    @objc func OpenProfile(){
        
        let vc = ProfileViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    
}
