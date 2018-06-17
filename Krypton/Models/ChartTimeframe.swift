//
//  ChartTimeframe.swift
//  Krypton
//
//  Created by Niklas Sauer on 17.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation

enum ChartTimeframe: Int {
    case week
    case month
    case threeMonth
    case sixMonth
    case year
    case twoYear
    case allTime
    
    var labelCount: Int {
        switch self {
        case .week:
            return 4
        case .month:
            return 4
        case .threeMonth:
            return 3
        case .sixMonth:
            return 6
        case .year:
            return 6
        case .twoYear:
            return 6
        case .allTime:
            return 6
        }
    }
    
//    var labelGranularity: (interval: Int, unit: Calendar.Component)? {
//        switch self {
//        case .week:
//            return (2, .day)
//        case .month:
//            return (7, .day)
//        case .threeMonth:
//            return (1, .month)
//        case .sixMonth:
//            return (1, .month)
//        case .year:
//            return (2, .month)
//        case .twoYear:
//            return (4, .month)
//        default:
//            return nil
//        }
//    }
    
    var comparisonDate: Date? {
        switch self {
        case .week:
            return Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case .month:
            return Calendar.current.date(byAdding: .month, value: -1, to: Date())
        case .threeMonth:
            return Calendar.current.date(byAdding: .month, value: -3, to: Date())
        case .sixMonth:
            return Calendar.current.date(byAdding: .month, value: -6, to: Date())
        case .year:
            return Calendar.current.date(byAdding: .year, value: -1, to: Date())
        case .twoYear:
            return Calendar.current.date(byAdding: .year, value: -2, to: Date())
        default:
            return nil
        }
    }
    
    var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        
        switch self {
        case .week:
            dateFormatter.setLocalizedDateFormatFromTemplate("EEE")
        case .month:
            dateFormatter.setLocalizedDateFormatFromTemplate("ddMM")
        case .threeMonth:
            dateFormatter.setLocalizedDateFormatFromTemplate("MMM")
        case .sixMonth:
            dateFormatter.setLocalizedDateFormatFromTemplate("MMM")
        case .year:
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMYY")
        case .twoYear:
            dateFormatter.setLocalizedDateFormatFromTemplate("MMMYY")
        default:
            break
        }
        
        return dateFormatter
    }
}
