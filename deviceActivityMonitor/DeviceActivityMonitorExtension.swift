//
//  DeviceActivityMonitorExtension.swift
//  deviceActivityMonitor
//
//  Created by Yaseen Halabi on 12/8/25.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import SwiftUI

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Handle the start of the interval.
        print("Interval started")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("Interval ended")
        // Handle the end of the interval.
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Handle the event reaching its threshold.
        // NOTE: For this to work, the main app and extension must share an App Group,
        // and UserDefaults must be initialized with that suite name.
        
        let selectedAppsKey = "selectedApps"
        let userDefaults = UserDefaults(suiteName: "group.yaseen.secondthought") ?? .standard
        
        if let data = userDefaults.data(forKey: selectedAppsKey),
           let selectedApps = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            
            let store = ManagedSettingsStore()
            store.shield.applications = selectedApps.applicationTokens
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selectedApps.categoryTokens)
            store.shield.webDomains = selectedApps.webDomainTokens
            print("EVENT DID REACH THRESHOLD - Blocked apps from group defaults")
        } else {
            print("EVENT DID REACH THRESHOLD - Failed to load selected apps from group defaults")
        }
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        // Handle the warning before the interval starts.
        print("INTERVAL WILL START")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        // Handle the warning before the interval ends.
        print("INTERVAL WILL END")
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        print("EVENT WILL REACH THRESHOLD WARNING")
        // Handle the warning before the event reaches its threshold.
    }
}
