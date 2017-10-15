//
//  SegmentedControlCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 15.10.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class SegmentedControlCell: UITableViewCell {

    // MARK: - Private Properties
    private var completion: ((Int) -> Void)?
    
    // MARK: - Outlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // MARK: - Navigation
    @IBAction func selectedSegment(_ sender: UISegmentedControl) {
        completion?(sender.selectedSegmentIndex)
    }
    
    // MARK: - Public Methods
    func configure(segments: [String], selectedSegment: Int, completion: ((Int) -> Void)?) {
        for (index, segmentTitle) in segments.enumerated() {
            segmentedControl.setTitle(segmentTitle, forSegmentAt: index)
        }
        
        segmentedControl.selectedSegmentIndex = selectedSegment
        self.completion = completion
    }

}
