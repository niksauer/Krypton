//
//  SectionHeaderCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 24.11.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class SectionHeaderCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var collapseImage: UIImageView!
    @IBOutlet weak var sectionTitleLabel: UILabel!
    @IBOutlet weak var rightDetailLabel: UILabel!
    
    // MARK: - Public Properties
    var isCollapsed: Bool = false {
        didSet {
            if isCollapsed {
                collapseImage.image = #imageLiteral(resourceName: "OT_expand-arrow")
            } else {
                collapseImage.image = #imageLiteral(resourceName: "OT_collapse-arrow")
            }
        }
    }
    
}
