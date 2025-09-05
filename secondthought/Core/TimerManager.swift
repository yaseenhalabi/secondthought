import Foundation
import FamilyControls

class TimerManager {
    static let shared = TimerManager()
    
    private let storage = UserDefaultsService.shared
    
    private var activeTimers: [String: [DispatchWorkItem]] = [:]
    private var blockExpirationTimes: [String: Date] = [:]
    
    weak var blockingDelegate: AppBlockingManagerDelegate?
    
    private init() {
        restoreState()
    }
    
    func restoreState() {
        blockExpirationTimes = storage.loadBlockExpirationTimes()
        cleanupExpiredBlocks()
        restoreActiveTimers()
    }
    
    private func cleanupExpiredBlocks() {
        let now = Date()
        var expiredSchemes: [String] = []
        
        for (scheme, expirationDate) in blockExpirationTimes {
            if now >= expirationDate {
                expiredSchemes.append(scheme)
            }
        }
        
        if !expiredSchemes.isEmpty {
            for scheme in expiredSchemes {
                blockExpirationTimes.removeValue(forKey: scheme)
                blockingDelegate?.unblockExpiredApp(scheme: scheme)
            }
            saveState()
        }
    }
    
    private func restoreActiveTimers() {
        let now = Date()
        
        for (scheme, expirationDate) in blockExpirationTimes {
            let timeRemaining = expirationDate.timeIntervalSince(now)
            
            if timeRemaining > 0 {
                scheduleUnblockTimer(for: scheme, delay: timeRemaining)
            }
        }
    }
    
    func startMonitoring(for urlScheme: String, timingMode: TimingMode, customDelay: Double? = nil) {
        cancelExistingTimers(for: urlScheme)
        
        let blockDelay = calculateBlockDelay(mode: timingMode, customDelay: customDelay)
        let totalExpirationTime = blockDelay + 600 // 10 minutes after blocking
        
        scheduleBlockTimer(for: urlScheme, delay: blockDelay)
        scheduleUnblockTimer(for: urlScheme, delay: totalExpirationTime)
        
        let expirationTime = Date().addingTimeInterval(totalExpirationTime)
        blockExpirationTimes[urlScheme] = expirationTime
        
        saveState()
    }
    
    private func calculateBlockDelay(mode: TimingMode, customDelay: Double?) -> Double {
        if let customDelay = customDelay {
            return customDelay
        }
        
        switch mode {
        case .defaultMode:
            return 10.0
        case .randomMode:
            return Double.random(in: 1.0...10.0)
        case .dynamicMode:
            return 2.0 // fallback
        }
    }
    
    private func scheduleBlockTimer(for urlScheme: String, delay: Double) {
        let blockWorkItem = DispatchWorkItem { [weak self] in
            self?.blockingDelegate?.blockApp(scheme: urlScheme)
        }
        
        addTimer(blockWorkItem, for: urlScheme)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: blockWorkItem)
    }
    
    private func scheduleUnblockTimer(for urlScheme: String, delay: Double) {
        let unblockWorkItem = DispatchWorkItem { [weak self] in
            self?.blockingDelegate?.unblockApp(scheme: urlScheme)
            self?.blockExpirationTimes.removeValue(forKey: urlScheme)
            self?.activeTimers.removeValue(forKey: urlScheme)
            self?.saveState()
        }
        
        addTimer(unblockWorkItem, for: urlScheme)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: unblockWorkItem)
    }
    
    private func addTimer(_ workItem: DispatchWorkItem, for urlScheme: String) {
        if activeTimers[urlScheme] == nil {
            activeTimers[urlScheme] = []
        }
        activeTimers[urlScheme]?.append(workItem)
    }
    
    func cancelExistingTimers(for urlScheme: String) {
        if let existingTimers = activeTimers[urlScheme] {
            existingTimers.forEach { $0.cancel() }
        }
        activeTimers[urlScheme] = []
    }
    
    func cancelAllTimers() {
        for (_, timers) in activeTimers {
            timers.forEach { $0.cancel() }
        }
        activeTimers.removeAll()
        blockExpirationTimes.removeAll()
        saveState()
    }
    
    func getExpirationTime(for urlScheme: String) -> Date? {
        return blockExpirationTimes[urlScheme]
    }
    
    func hasActiveTimer(for urlScheme: String) -> Bool {
        return blockExpirationTimes[urlScheme] != nil
    }
    
    private func saveState() {
        storage.saveBlockExpirationTimes(blockExpirationTimes)
    }
}

protocol AppBlockingManagerDelegate: AnyObject {
    func blockApp(scheme: String)
    func unblockApp(scheme: String)
    func unblockExpiredApp(scheme: String)
}
