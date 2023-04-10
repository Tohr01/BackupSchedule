//
// AppDelegate.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static var tm: TimeMachine?
    var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        do {
            AppDelegate.tm = try TimeMachine.init()
            
            if !(try AppDelegate.tm!.isConfigured()) {
                openVC(title: "Configure TimeMachine", storyboardID: "configuretm")
            } else if AppDelegate.tm!.isAutoBackupEnabled() {
                openVC(title: "Disable AutoBackup", storyboardID: "disableab")
            } else {
                openMainVC(nil)
            }
        } catch {
            communicationError()
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(openMainVC(_:)), name: Notification.Name("disabledautobackup"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openMainVC(_:)), name: Notification.Name("tmconfigured"), object: nil)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}

// MARK: -
// MARK: Window handling
extension AppDelegate {
    @objc func openMainVC(_ aNotification: Notification?) {
        if (AppDelegate.tm!.isAutoBackupEnabled()) {
            openVC(title: "Disable AutoBackup", storyboardID: "disableab")
        } else {
            openVC(title: "Schedule Backups", storyboardID: "scheduleconfiguration")
        }
    }
    
    func openVC(title: String, storyboardID: String) {
        if window == nil || !window.isVisible {
            let contentRect = NSRect(x: 0, y: 0, width: 820, height: 498)
            window = NSWindow(contentRect: contentRect, styleMask: [.closable, .miniaturizable, .titled, ], backing: .buffered, defer: false)
            
            window.isReleasedWhenClosed = false
            window.center()
            window.title = title
            window.orderFrontRegardless()
            
            let storyboard = NSStoryboard.init(name: "Main", bundle: nil)
            
            if let vc = storyboard.instantiateController(withIdentifier: storyboardID) as? NSViewController {
                window.contentViewController = vc
            }
            
        } else {
            let storyboard: NSStoryboard = NSStoryboard.init(name: "Main", bundle: nil)
            
            if let vc = storyboard.instantiateController(withIdentifier: storyboardID) as? NSViewController {
                window.title = title
                window.contentViewController = vc
            }
            window.orderFrontRegardless()
        }
    }
}

// MARK: -
// MARK: Error handling
extension AppDelegate {
    func communicationError() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Error communicating with TimeMachine. Please report this bug."
        alert.runModal()
    }
}
