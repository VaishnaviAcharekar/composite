//
//  LoginViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit

class LoginViewController: UIViewController {

    
    @IBOutlet weak var LogIn: UIButton!
    @IBOutlet weak var PasswordTxt: UITextField!
    
    @IBOutlet weak var emailTXT: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        LogIn.layer.cornerRadius = 30.0
        emailTXT.layer.cornerRadius = 30.0
        emailTXT.layer.borderColor = UIColor.black.cgColor
        emailTXT.layer.borderWidth = 0.5
//        emailTXT.placeholder = "Enter Your Email"
     
        
        PasswordTxt.layer.borderColor = UIColor.black.cgColor
        PasswordTxt.layer.borderWidth = 0.5
        
        PasswordTxt.layer.cornerRadius = 30.0
        
        LogIn.backgroundColor =  UIColor.lightingPurpleColor
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        emailTXT.attributedPlaceholder = NSAttributedString(
            string: "Enter Your e-mail",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        PasswordTxt.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
    }
    
    @IBAction func logInBtn(_ sender: UIButton) {
        self.view.endEditing(true)
        
        if !self.isValidate() {
            return
        }
        
        let vc = StartScanViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
        
    }
    
    private func isValidate() -> Bool {
        
        if emailTXT.text != "" && PasswordTxt.text != "" {
            return true
        }else{
            return false
        }
        
    }
    
    @IBAction func SignUp(_ sender: UIButton) {
        
        let vc = RegisterViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @objc override func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}
