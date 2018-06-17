//
//  LargeValueFormatter.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import Charts

class LargeValueFormatter: IValueFormatter, IAxisValueFormatter {
    
    /// Suffix to be appended after the values.
    ///
    /// **default**: suffix: ["", "k", "m", "b", "t"]
    var suffix = ["", "k", "m", "b", "t"]
    
    private func format(value: Double) -> String {
        let sign = copysign(1.0, value)
        var sig = abs(value)
        var length = 0
        let maxLength = suffix.count - 1
        
        while sig >= 1000.0 && length < maxLength {
            sig /= 1000.0
            length += 1
        }
        
        return String(format: "%2.f", sign*sig) + suffix[length]
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return format(value: value)
    }
    
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        return format(value: value)
    }
    
}
