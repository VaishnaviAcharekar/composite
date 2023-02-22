//
//  ProfileTableViewCell.swift
//  Composite53
//
//  Created by user on 15/02/23.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {

    @IBOutlet weak var labelTag: UILabel!
    
    @IBOutlet weak var valuetag: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
}
