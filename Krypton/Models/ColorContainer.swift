//
//  ColorContainer.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import UIKit

struct ColorContainer: DashboardColorPalette {
    private let red = UIColor(red: 242/255, green: 85/255, blue: 85/255, alpha: 1)
    private let blue = UIColor(red: 87/255, green: 169/255, blue: 232/255, alpha: 1)
    private let darkBlue = UIColor(red: 35/255, green: 45/255, blue: 52/255, alpha: 1)
    private let green = UIColor(red: 68/255, green: 203/255, blue: 132/255, alpha: 1)
    
    private let white = UIColor(red: 227/255, green: 229/255, blue: 229/255, alpha: 1)
    private let black = UIColor(red: 19/255, green: 21/255, blue: 25/255, alpha: 1)
    
    private let gray = UIColor(red: 152/255, green: 166/255, blue: 173/255, alpha: 1)
    private let darkGray = UIColor(red: 28/255, green: 31/255, blue: 35/255, alpha: 1)
    
    var backgroundColor: UIColor { return black }
    var tintColor: UIColor { return blue }
    
    var primaryTextColor: UIColor { return white }
    var secondaryTextColor: UIColor { return gray }
    
    var neutralColor: UIColor { return blue }
    var negativeColor: UIColor { return red }
    var positiveColor: UIColor { return green }
    
    var chartLineColor: UIColor { return blue }
    var chartFillColor: UIColor { return darkBlue }
    var chartBackgroundColor: UIColor { return darkGray }
    var chartGridColor: UIColor { return darkBlue }

    var insightBackgroundColor: UIColor { return darkGray }
    
    var separatorColor: UIColor { return UIColor(displayP3Red: 55/255, green: 56/255, blue: 59/255, alpha: 1)}

}
