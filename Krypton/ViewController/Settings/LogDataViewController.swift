//
//  LogDataViewController.swift
//  Krypton
//
//  Created by Niklas Sauer on 14.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import ToolKit

class LogDataViewController: TextViewController {
    
    // MARK: - Public Properties
    let path: URL
    
    // MARK: - Initialization
    init?(path: URL) {
        self.path = path
        
        do {
            let log = try String(contentsOf: path, encoding: .utf8)
            super.init(text: log)
            self.title = "Log Data"
        } catch {
            log.error("Failed to load log data from path: \(error)")
            return nil
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
