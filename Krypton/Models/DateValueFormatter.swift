//
//  DateValueFormatter.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import Charts

class DateValueFormatter: IAxisValueFormatter {
    
    // MARK: - Private Properties
    private var dateFormatter: DateFormatter
    
    // MARK: - Initialization
    init(dateFormatter: DateFormatter) {
        self.dateFormatter = dateFormatter
    }
    
    // MARK: - Public Methods
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: value + referenceTimestamp!))
    }
    
}
