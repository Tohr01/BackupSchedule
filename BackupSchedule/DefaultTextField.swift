//
// DefaultTextField.swift
// BackupSchedule
//
// Created by Tohr01 on 20.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class DefaultTextFieldView: NSView {
    
    @IBInspectable var cornerRadius: CGFloat = 7
    
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
        self.layer?.backgroundColor = .white
        
        let textField = DefaultTextField(frame: dirtyRect)
                textField.stringValue = "Hello, world!"
                textField.font = NSFont.systemFont(ofSize: 14)
                textField.textColor = NSColor.black
                
                // Add the text field to the view
                self.addSubview(textField)
    }
    
}

class DefaultTextField: NSTextField {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.isBordered = false
        self.layer?.backgroundColor = .clear
        self.focusRingType = .none
        self.layer?.cornerRadius = 7
    }
}
