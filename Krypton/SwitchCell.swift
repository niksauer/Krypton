//
//  SwitchCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class SwitchCell: UITableViewCell {
    
    // MARK: - Public Properties
    var completion: (() -> Void)!
    
    // MARK: - Outlets
    @IBOutlet weak var toggleLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    // MARK: - Navigatiom
    @IBAction func toggledSwitch(_ sender: UISwitch) {
        completion()
    }
    
    // MARK: - Public Methods
    func configure(name: String, state: Bool, completion: @escaping () -> Void) {
        toggleLabel.text = name
        toggleSwitch.isOn = state
        self.completion = completion
    }
    
}
