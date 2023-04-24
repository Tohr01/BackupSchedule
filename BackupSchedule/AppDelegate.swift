//
// AppDelegate.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//


import Cocoa
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    static var tm: TimeMachine?
    var window: NSWindow!
    private var menu: NSMenu!
    private var statusItem: NSStatusItem!
    private var backupTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            AppDelegate.tm = try TimeMachine.init()
            
            // Construct menubar appearance
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            if let button = statusItem.button {
                button.image = NSImage(named: "tmicon")
                try constructMenu()
            }
            
            Task {
                await requestNotificationAuth()
            }
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
        
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(backupStarted(_:)), name: NSNotification.Name("com.apple.backupd.DestinationMountNotification"), object: nil)
    }
    
    @objc func test(_ aNotification: Notification) {
        print(aNotification)
    }
    func applicationWillTerminate(_ aNotification: Notification) {
        let workspaceNC = NSWorkspace.shared.notificationCenter
        workspaceNC.removeObserver(self, name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        workspaceNC.removeObserver(self, name: NSWorkspace.didTerminateApplicationNotification, object: nil)
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
// MARK: Notification handling
extension AppDelegate {
    func requestNotificationAuth() async {
        let notificationCenter = UNUserNotificationCenter.current()
        _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound])
    }
}

// MARK: -
// MARK: Menu construction
extension AppDelegate {
#warning("todo menu creation")
    func constructMenu() throws {
        menu = NSMenu()
        
        do {
            if !(try AppDelegate.tm!.isConfigured()) {
                let notConfiguredItem = NSMenuItem(title: "TimeMachine not configured", action: nil, keyEquivalent: "")
                notConfiguredItem.isEnabled = false
                menu.addItem(notConfiguredItem)
                
            } else {
                let topMenuItem: NSMenuItem?
                if let backupRunning = try? AppDelegate.tm!.isBackupRunning(), backupRunning {
                    backupStarted(Notification(name: Notification.Name("com.apple.backupd.DestinationMountNotification")))
                    #warning("todo")
                    menu.addItem(NSMenuItem.separator())
                } else if let lastBackupDate = AppDelegate.tm!.getLatestBackup() {
                    topMenuItem = NSMenuItem(title: "Last Backup \(lastBackupDate.getLatestBackupString())", action: nil, keyEquivalent: "")
                    topMenuItem!.identifier = NSUserInterfaceItemIdentifier("topMenuItem")
                    topMenuItem!.isEnabled = false
                    menu.addItem(topMenuItem!)
                    menu.addItem(NSMenuItem.separator())
                }
                
                let backupNowItem = NSMenuItem(title: "Start Backup", action: #selector(AppDelegate.startBackupWrapper), keyEquivalent: "")
                menu.addItem(backupNowItem)
            }
        } catch {
            throw error
        }
        
        let quitNowitem = NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "")
        menu.addItem(quitNowitem)
        statusItem.menu = menu
    }
}

// MARK: -
// MARK: TM Listeners
extension AppDelegate {
    @objc func backupStarted(_ aNotification: Notification) {
        // test if backup is running
        if let backupRunning = try? AppDelegate.tm!.isBackupRunning(), !backupRunning { return }
        
        
        backupTimer = Timer(timeInterval: 5, target: self, selector: #selector(updateTMProgressMenu), userInfo: nil, repeats: true)
        RunLoop.main.add(backupTimer!, forMode: .common)
    }
    
    @objc func updateTMProgressMenu() {
        if let backupRunning = try? AppDelegate.tm!.isBackupRunning(), !backupRunning {
            backupTimer?.invalidate()
            if let menuItem = menu.item(at: 0) {
                menuItem.title = "Last backup \(AppDelegate.tm!.getLatestBackup().getLatestBackupString() ?? "No latest Backup found")"
            }
            return
        }
        if let menuItem = menu.item(at: 0) {
            if let menuItem = menu.item(at: 0) {
                menuItem.title = "Running Backup"
            }
        }
           
    }
}

// MARK: -
// MARK: TM Wrapper for menu
extension AppDelegate {
    @objc func startBackupWrapper() {
        try? AppDelegate.tm!.startBackup()
    }
    
    @objc func quitApplication() {
        NSApplication.shared.terminate(self)
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
