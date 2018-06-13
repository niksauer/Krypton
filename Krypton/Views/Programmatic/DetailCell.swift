//
//  DetailCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 13.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import UIKit

class DetailCell: UITableViewCell {
    
    // Mark: - Views
    let label = UILabel()
    let detailLabel = UILabel()
    
    // Mark: - Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        detailLabel.textColor = UIColor.lightGray
        
        contentView.addSubview(label)
        contentView.addSubview(detailLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Mark: - Customization
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 760), for: .horizontal)
        detailLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 760), for: .horizontal)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: detailLabel.leadingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            detailLabel.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
}
