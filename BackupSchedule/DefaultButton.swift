//
// DefaultButton.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Cocoa

class DefaultButton: NSButton {
    @IBInspectable var bgColorActive: NSColor = NSColor(named: "defaultColor")!
    @IBInspectable var bgColorInactive: NSColor = NSColor.white
    @IBInspectable var textColorActive: NSColor = NSColor.white
    @IBInspectable var textColorInactive: NSColor = NSColor(named: "activeTextColor")!
    @IBInspectable var cornerRadius: CGFloat = 7
    @IBInspectable var completeRoundWhenFocus: Bool = false
    
    @IBInspectable var canToggle: Bool = true
    @IBInspectable var isActive: Bool = false
    @IBInspectable var toggleButtonOnly: Bool = true
    @IBInspectable var broadcastNotificationWhenClicked: Bool = false
    @IBInspectable var broadcastNotificationName: String = ""
    
    @IBInspectable var dropShadow: Bool = true
    @IBInspectable var shadowOffset: CGSize = CGSize(width: 0, height: 5)
    @IBInspectable var shadowOpacity: Float = 0.2
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if dropShadow {
            self.layer?.masksToBounds = false
            self.wantsLayer = true
            self.layer?.shadowColor = .black
            self.layer?.shadowOffset = shadowOffset
            self.layer?.shadowRadius = 5
            self.layer?.shadowOpacity = shadowOpacity
        }
        
        self.layer?.cornerRadius = cornerRadius
        
        setTitleColor(color: isActive ? textColorActive : textColorInactive)
        setBackgroundColor(color: isActive ? bgColorActive : bgColorInactive)
        // Add button hover effect
        let hoverTrackingArea = NSTrackingArea.init(rect: self.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(hoverTrackingArea)
        
        // Add button selector action
        if toggleButtonOnly {
            self.target = self
            self.action = #selector(buttonPressed(_:))
        }
    }
    
    func setTitleColor(color: NSColor) {
        if #available(macOS 10.14, *) {
            self.contentTintColor = color
        } else {
            // Fallback on earlier versions
#warning("fix")
            // self.set_title_color(color: color)
        }
    }
    
    func setBackgroundColor(color: NSColor) {
        self.layer?.backgroundColor = color.cgColor
    }
    
    func toggle() {
        if isActive {
            setInactive()
        } else {
            setActive()
        }
    }
    func setActive() {
        isActive = true
        setTitleColor(color: textColorActive)
        setBackgroundColor(color: bgColorActive)
    }
    
    func setInactive() {
        isActive = false
        setTitleColor(color: textColorInactive)
        setBackgroundColor(color: bgColorInactive)
    }
    
    @objc func buttonPressed(_ sender: Any?) {
        if canToggle {
            toggle()
        }
        if broadcastNotificationWhenClicked {
            NotificationCenter.default.post(name: Notification.Name(broadcastNotificationName), object: nil)
        }
    }
}

// MARK: -
// MARK: Hover effect
extension DefaultButton {
    /// On mouse entering
    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            self.animator().layer?.backgroundColor = isActive ? bgColorActive.darken(by: 0.1).cgColor : bgColorInactive.darken(by: 0.1).cgColor
            self.animator().layer?.cornerRadius = completeRoundWhenFocus ? (self.frame.size.width / 2) : cornerRadius+5
        }
    }
    
    /// On mouse leaving
    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            self.animator().layer?.backgroundColor = isActive ? bgColorActive.cgColor : bgColorInactive.cgColor
            self.animator().layer?.cornerRadius = cornerRadius
        }
    }
    override func mouseDown(with event: NSEvent) {
        _ = self.target?.perform(self.action, with: self)
    }
}

