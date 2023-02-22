//
//  ProfileViewController.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   

    @IBOutlet weak var InformationView: UITableView!
    
    
    var labels = ["Name", "E-mail", "Phone"]
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        InformationView.delegate = self
        InformationView.dataSource = self
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  InformationView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ProfileTableViewCell
        cell.labelTag.text = labels[indexPath.row]
        cell.valuetag.text = Values[indexPath.row]
        
        return cell
    }
    
    @IBAction func BackBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
   
}
