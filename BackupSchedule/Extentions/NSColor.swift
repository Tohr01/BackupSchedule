//
// NSColor.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        
import AppKit

extension NSColor {
    
    func darken(by amount: CGFloat) -> NSColor {
        var r1: CGFloat = CGFloat()
        var g1: CGFloat = CGFloat()
        var b1: CGFloat = CGFloat()
        var a1: CGFloat = CGFloat()
        
        self.usingColorSpace(NSColorSpace.sRGB)!.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        
        let new_color: NSColor = NSColor.init(red: r1 - amount, green: g1 - amount, blue: b1 - amount, alpha: a1)
        return new_color
    }
}
