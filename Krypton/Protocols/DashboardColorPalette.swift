//
//  DashboardColorPalette.swift
//  Krypton
//
//  Created by Niklas Sauer on 18.06.18.
//  Copyright © 2018 Hewlett Packard Enterprise. All rights reserved.
//

import Foundation
import UIKit

protocol DashboardColorPalette {
    var backgroundColor: UIColor { get }
    var neutralColor: UIColor { get }
    var negativeColor: UIColor { get }
    var positiveColor: UIColor { get }
    var chartLineColor: UIColor { get }
    var chartFillColor: UIColor { get }
    var chartBackgroundColor: UIColor { get }
    var chartGridColor: UIColor { get }
    var primaryTextColor: UIColor { get }
    var secondaryTextColor: UIColor { get }
    var tintColor: UIColor { get }
    var insightBackgroundColor: UIColor { get }
    var separatorColor: UIColor { get }
}
