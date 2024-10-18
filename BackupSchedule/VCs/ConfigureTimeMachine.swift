//
// ConfigureTimeMachine.swift
// BackupSchedule
//
// Created by Tohr01 on 18.03.23
// Copyright © 2023 Tohr01. All rights reserved.
//

import Cocoa

class ConfigureTimeMachine: NSViewController {
    @IBOutlet var loadingSpinner: NSProgressIndicator!
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        loadingSpinner.startAnimation(self)
        timer = Timer(timeInterval: TimeInterval(2), repeats: true, block: { _ in
            // Check permission
            let configured = try? AppDelegate.tm?.isConfigured()

            if let configured = configured, configured {
                self.timer?.invalidate()
                NotificationCenter.default.post(name: NSNotification.Name("tmconfigured"), object: nil)
            }
        })
        RunLoop.main.add(timer!, forMode: .default)
    }

    @IBAction func configureTM(_: Any) {
        let tmPrefsLocation = "/System/Library/PreferencePanes/TimeMachine.prefPane"
        var tmPrefsURL: URL?
        if #available(macOS 13.0, *) {
            tmPrefsURL = URL(filePath: tmPrefsLocation)
        } else {
            // Fallback on earlier versions
            tmPrefsURL = URL(fileURLWithPath: tmPrefsLocation)
        }

        if let tmPrefsURL = tmPrefsURL {
            NSWorkspace().open(tmPrefsURL)
        }
    }
}
