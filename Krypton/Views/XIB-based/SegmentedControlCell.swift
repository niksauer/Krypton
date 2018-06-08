//
//  SegmentedControlCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.10.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class SegmentedControlCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // MARK: - Private Properties
    private var onChange: ((Int) -> Void)?
    
    // MARK: - Private Methods
    @IBAction func selectedSegment(_ sender: UISegmentedControl) {
        onChange?(sender.selectedSegmentIndex)
    }
    
    // MARK: - Public Methods
    func configure(segments: [String], selectedSegment: Int, onChange: ((Int) -> Void)?) {
        segmentedControl.removeAllSegments()
        
        for (index, segmentTitle) in segments.enumerated() {
            segmentedControl.insertSegment(withTitle: segmentTitle, at: index, animated: false)
        }
        
        segmentedControl.selectedSegmentIndex = selectedSegment
        self.onChange = onChange
    }

}
