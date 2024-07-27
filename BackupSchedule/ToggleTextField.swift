//
// ToggleTextField.swift
// BackupSchedule
//
// Created by Tohr01 on 12.12.23
// Copyright © 2023 Tohr01. All rights reserved.
//
        

import Cocoa

class ToggleTextField: NSTextField {
    public func addClickGestureRecognizer(target: AnyObject, selector: Selector) {
        let gestureRecognizer = NSClickGestureRecognizer()
        gestureRecognizer.target = target
        gestureRecognizer.buttonMask = 0x1
        gestureRecognizer.action = selector
        self.addGestureRecognizer(gestureRecognizer)
    }
}
