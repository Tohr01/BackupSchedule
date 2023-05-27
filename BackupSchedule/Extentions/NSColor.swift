//
// NSColor.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import AppKit

extension NSColor {
    func darken(by amount: CGFloat, addAlphaWhenZero: CGFloat = 0.0) -> NSColor {
        var r1 = CGFloat()
        var g1 = CGFloat()
        var b1 = CGFloat()
        var a1 = CGFloat()

        usingColorSpace(NSColorSpace.sRGB)!.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

        var newColor: NSColor
        if r1 == 0, g1 == 0, b1 == 0 {
            newColor = NSColor(red: r1, green: g1, blue: b1, alpha: a1 + addAlphaWhenZero)
        } else {
            newColor = NSColor(red: r1 - amount, green: g1 - amount, blue: b1 - amount, alpha: a1)
        }
        return newColor
    }
}
