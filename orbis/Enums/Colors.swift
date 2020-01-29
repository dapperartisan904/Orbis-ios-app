//
//  Colors.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit

private let GroupSolidColors = [
    "#263238",
    "#607D8B",
    "#D0D0D0",
    "#9E9E9E",
    "#795548",
    "#C0CA33",
    "#2196F3",
    "#FF8A65",
    "#FF9800",
    "#FFEB3B",
    "#8BC34A",
    "#9C27B0",
    "#009688",
    "#00BCD4",
    "#E91E63",
    "#F44336"
]

private let GroupStrokeColors = [
    "#181C1D",
    "#364045",
    "#8D8D8D",
    "#505050",
    "#4A3E3A",
    "#51551D",
    "#133A58",
    "#844E3C",
    "#885100",
    "#8D8223",
    "#4A711E",
    "#51145C",
    "#005A52",
    "#01606C",
    "#981441",
    "#992A22"
]

let tabActiveColor = "#4b4b4b"
let tabInactiveColor = "#bfbfbf"

func textColorPrimary() -> UIColor {
    return UIColor(rgba: "#0b0b0b")
}

func textColorShouldBeDark(group: Group?) -> Bool {
    return textColorShouldBeDark(colorIndex: group?.colorIndex ?? -1)
}

func textColorShouldBeDark(colorIndex: Int) -> Bool {
    return colorIndex == 2 || colorIndex == 9
}

func textColor(colorIndex: Int?) -> UIColor {
    guard let colorIndex = colorIndex else {
        return textColorPrimary()
    }
    return textColorShouldBeDark(colorIndex: colorIndex) ? textColorPrimary() : UIColor.white
}

func lightBlueColor() -> UIColor {
    return UIColor(rgba: "#E1EBEB")
}

func groupSolidColor(group: Group) -> UIColor {
    return UIColor(rgba: GroupSolidColors[group.colorIndex!])
}

func groupSolidColor(group: Group?, defaultColor: UIColor) -> UIColor {
    if let g = group {
        return groupSolidColor(group: g)
    }
    else {
        return defaultColor
    }
}

func groupStrokeColor(group: Group) -> UIColor {
    return UIColor(rgba: GroupStrokeColors[group.colorIndex!])
}

func groupSolidColor(index: Int) -> UIColor {
    return UIColor(rgba: GroupSolidColors[index])
}

func groupStrokeColor(index: Int) -> UIColor {
    return UIColor(rgba: GroupStrokeColors[index])
}

func groupSolidColorHex(index: Int) -> String {
    return GroupSolidColors[index]
}

func groupStrokeColorHex(index: Int) -> String {
    return GroupStrokeColors[index]
}

func groupColorIsLight(group: Group?) -> Bool {
    return [2, 9].contains(group?.colorIndex ?? 2)
}

func groupColorIsDark(group: Group?) -> Bool {
    return !groupColorIsLight(group: group)
}

func numberOfSolidColors() -> Int {
    return GroupSolidColors.count
}
