//
// BackgroundView.swift
// BackupSchedule
//
// Created by Tohr01 on 19.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class BackgroundView: NSView {
    @IBInspectable var alphaComponent: CGFloat = 0.07
    @IBInspectable var backgroundColor: NSColor = .quaternaryLabelColor
    @IBInspectable var hoverDarken: Bool = false
    @IBInspectable var cornerRadius: CGFloat = 0.0
    
    @IBInspectable var dropShadow: Bool = false
    @IBInspectable var shadowOffset: CGSize = CGSize(width: 0, height: 0)
    @IBInspectable var shadowOpacity: Float = 0.1
    
    var defaultBackgroundColor: NSColor!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.wantsLayer = true
        
        if dropShadow {
            self.layer?.masksToBounds = false
            self.layer?.shadowColor = .black
            self.layer?.shadowOffset = shadowOffset
            self.layer?.shadowRadius = 5
            self.layer?.shadowOpacity = shadowOpacity
        }
        
        defaultBackgroundColor = backgroundColor.withAlphaComponent(alphaComponent)
        
        self.layer?.backgroundColor = defaultBackgroundColor.cgColor
        self.layer?.cornerRadius = cornerRadius
        
        if hoverDarken {
            let trackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited], owner: self, userInfo: nil)
            self.addTrackingArea(trackingArea)
        }
    }
    
    /// On mouse Enter
    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            self.animator().layer?.backgroundColor = defaultBackgroundColor.darken(by: 0.2, addAlphaWhenZero: 0.07).cgColor
        }
    }
    
    /// On mouse leaving
    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            self.animator().layer?.backgroundColor = defaultBackgroundColor.cgColor
        }
    }
    
}
