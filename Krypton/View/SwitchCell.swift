//
//  SwitchCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 Hewlett Packard Enterprise. All rights reserved.
//

import UIKit

class SwitchCell: UITableViewCell {
    
    // MARK: - Private Properties
    private var completion: ((Bool) -> Void)?
    
    // MARK: - Outlets
    @IBOutlet weak var toggleLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    // MARK: - Navigation
    @IBAction func toggledSwitch(_ sender: UISwitch) {
        completion?(sender.isOn)
    }
    
    // MARK: - Public Methods
    func configure(name: String, isOn: Bool, completion: ((Bool) -> Void)?) {
        toggleLabel.text = name
        toggleSwitch.isOn = isOn
        self.completion = completion
    }
    
}
