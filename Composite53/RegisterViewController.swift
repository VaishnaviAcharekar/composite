//
//  RegisterViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var firstName: UITextField!
    
    @IBOutlet weak var lastNmae: UITextField!
    
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var phone: UITextField!
    
    @IBOutlet weak var confirmpassword: UITextField!
    @IBOutlet weak var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        firstName.layer.cornerRadius = 30.0
        firstName.layer.borderColor = UIColor.black.cgColor
        firstName.layer.borderWidth = 0.5
        firstName.attributedPlaceholder = NSAttributedString(
            string: "Enter your First Name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        lastNmae.layer.cornerRadius = 30.0
        lastNmae.layer.borderColor = UIColor.black.cgColor
        lastNmae.layer.borderWidth = 0.5
        lastNmae.attributedPlaceholder = NSAttributedString(
            string: "Enter your Last Name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        email.layer.cornerRadius = 30.0
        email.layer.borderColor = UIColor.black.cgColor
        email.layer.borderWidth = 0.5
        email.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        phone.layer.cornerRadius = 30.0
        phone.layer.borderColor = UIColor.black.cgColor
        phone.layer.borderWidth = 0.5
        phone.attributedPlaceholder = NSAttributedString(
            string: "Phone Number",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        confirmpassword.layer.cornerRadius = 30.0
        confirmpassword.layer.borderColor = UIColor.black.cgColor
        confirmpassword.layer.borderWidth = 0.5
        confirmpassword.attributedPlaceholder = NSAttributedString(
            string: "Confirm Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        password.layer.cornerRadius = 30.0
        password.layer.borderColor = UIColor.black.cgColor
        password.layer.borderWidth = 0.5
        password.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        
        registerBtn.layer.cornerRadius = 30.0
        registerBtn.backgroundColor = UIColor.lightingPurpleColor
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        
    }
    
    @IBAction func LogIn(_ sender: UIButton) {
        
        
        self.navigationController?.popViewController(animated: true)
        
    }
    
    @IBAction func register(_ sender: UIButton) {
        
        if !isValidate(){
            return
        }
        
        
        FirstName = firstName.text ?? "John"
        Lastname = lastNmae.text ?? "capreese"
        Email = email.text ?? "john@123"
        Phone = phone.text ?? "1234"
        
        let vc = StartScanViewController.loadViewController(withStoryBoard: .mainSB)
        
        self.navigationController?.pushViewController(vc, animated: true)
        
        
    }
    
    private func isValidate() -> Bool {
        
        if firstName.text != "" && lastNmae.text != "" && email.text != "" && phone.text != "" && password.text != "" && confirmpassword.text != "" {
            return true
        }else{
            return false
        }
        
    }

}
