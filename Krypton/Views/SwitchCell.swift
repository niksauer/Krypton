//
//  SwitchCell.swift
//  Krypton
//
//  Created by Niklas Sauer on 16.09.17.
//  Copyright © 2017 SauerStudios. All rights reserved.
//

import UIKit

class SwitchCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var toggleLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!
    
    // MARK: - Private Properties
    private var onChange: ((Bool) -> Void)?
    
    // MARK: - Private Methods
    @IBAction private func toggledSwitch(_ sender: UISwitch) {
        onChange?(sender.isOn)
    }
    
    // MARK: - Public Methods
    func configure(name: String, isOn: Bool, onChange: ((Bool) -> Void)?) {
        toggleLabel.text = name
        toggleSwitch.isOn = isOn
        self.onChange = onChange
    }
    
}
