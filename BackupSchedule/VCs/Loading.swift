//
// Loading.swift
// BackupSchedule
//
// Created by Tohr01 on 25.09.24
// Copyright © 2024 Tohr01. All rights reserved.
//
        

import Cocoa

class Loading: NSViewController {

    @IBOutlet var progressIndicator: NSProgressIndicator!
    
    let NUM_OPERATIONS = 4
    
    var tmTargets: [TMDestination] = []
    var primaryDisk: TMDestination?
    var volumeCount: Int = 1
    var lastBackupString: String = "No latest Backup found"
    
    override func viewDidAppear() {
        progressIndicator.startAnimation(nil)
        tmTargets = (try? AppDelegate.tm!.getDestinations()) ?? []
        progressIndicatorStepUp()
        primaryDisk = try? AppDelegate.tm.getPrimaryVolume()
        progressIndicatorStepUp()
        volumeCount = (try? AppDelegate.tm.getBackupVolumeCount()) ?? 1
        progressIndicatorStepUp()
        lastBackupString = AppDelegate.tm.getLatestBackupStr()
        progressIndicatorStepUp()
        progressIndicator.stopAnimation(nil)
        performSegue(withIdentifier: "loadingToMain", sender: self)
    }
    
    func progressIndicatorStepUp() {
        progressIndicator.increment(by: Double(100 / NUM_OPERATIONS))
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destVC = segue.destinationController as? ScheduleConfiguration {
            destVC.tmTargets = tmTargets
            destVC.primaryDisk = primaryDisk
            destVC.volumeCount = volumeCount
            destVC.lastBackupString = lastBackupString
        }
    }
}
