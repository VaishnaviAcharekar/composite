//
//  Global.swift
//  Composite53
//
//  Created by user on 16/02/23.
//

import Foundation

var FirstName : String = ""
var Lastname : String = ""
var Email: String = ""
var Phone: String = ""
var password: String = ""
var confirmpasswprd: String = ""
var Values = [FirstName, Lastname,  Phone]


import SVProgressHUD

/// Show loader
public func showLoader() {
    OperationQueue.main.addOperation {
        SVProgressHUD.setDefaultMaskType(.gradient)
        SVProgressHUD.show()
    }
}

/// Hide loader
public func hideLoader() {
    OperationQueue.main.addOperation {
        SVProgressHUD.dismiss()
    }
}
