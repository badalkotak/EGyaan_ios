//
//  TimetableDetailedCellViewController.swift
//  EGyaan
//
//  Created by Badal Kotak on 26/06/17.
//  Copyright © 2017 EGyaan. All rights reserved.
//

import UIKit

class TimetableDetailedCellViewController: UITableViewCell {
//    @IBOutlet var timeLabel: UILabel!
//    @IBOutlet var teacherLabel: UILabel!
//    @IBOutlet var courseLabel: UILabel!
//    @IBOutlet var cellView: UIView!
//    
//    @IBOutlet var colorLabel: UILabel!
    
    @IBOutlet var courseLabel: UILabel!
    
    @IBOutlet var cellView: UIView!
    @IBOutlet var teacherLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}

