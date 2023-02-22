//
//  PastScansTableViewCell.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit

class PastScansTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ScanName: UILabel!
    
    @IBOutlet weak var DateLbl: UILabel!
    
    @IBOutlet weak var imgView: UIImageView!
    
    @IBOutlet weak var openBtn: UIButton!
    
    var blockForFeedbackClick: ((_ index: Int) -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @IBAction func OpenBtn(_ sender: UIButton) {
        showLoader()
        sender.isSelected = !sender.isSelected
        
        if self.blockForFeedbackClick != nil {
            print("sender.tag", sender.tag)
            self.blockForFeedbackClick!(sender.tag)
        }
        
        
    }
    
    

}
