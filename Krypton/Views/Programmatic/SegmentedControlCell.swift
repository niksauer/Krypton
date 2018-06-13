//
//  SegmentedControlCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class SegmentedControlCell: UITableViewCell {

    // MARK: - Views
    let segmentedControl = UISegmentedControl()
    
    // MARK: - Initialization
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = UIColor.clear
        
        contentView.addSubview(segmentedControl)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Customization
    override func layoutSubviews() {
        super.layoutSubviews()
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            segmentedControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    // MARK: - Public Methods
    func setup(segments: [String], selectedSegment: Int) {
        segmentedControl.removeAllSegments()
        
        for (index, segmentTitle) in segments.enumerated() {
            segmentedControl.insertSegment(withTitle: segmentTitle, at: index, animated: false)
        }
        
        segmentedControl.selectedSegmentIndex = selectedSegment
    }
    
}
