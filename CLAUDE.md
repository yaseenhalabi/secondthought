# Second Thought - iOS App Overview

## App Purpose
Second Thought is an iOS parental control/digital wellness app that helps users create intentional friction when accessing distracting social media apps. When users try to open configured apps (Instagram, TikTok, etc.), the app temporarily unblocks them but starts a timer to re-block them after a brief period.

## Core Architecture

### Main Components
- **ContentView.swift** (950 lines): Main UI controller handling app selection, blocking logic, timers, and user interface
- **ActivateSecondThoughtIntent.swift** (170 lines): App Intent that integrates with Shortcuts/Siri to handle app unblocking requests
- **secondthoughtApp.swift**: Standard SwiftUI App entry point

### Key Technologies Used
- **SwiftUI**: Modern declarative UI framework
- **FamilyControls**: Apple's Screen Time API for app blocking/shielding
- **ManagedSettings**: Manages app restrictions and shields
- **DeviceActivity**: Monitors device usage (requested but not heavily used)
- **AppIntents**: Siri Shortcuts integration for voice activation

## Core Features

### 1. App Selection & Configuration
- Users select which apps to monitor using `FamilyActivityPicker`
- App stores `FamilyActivitySelection` with `ApplicationToken`s
- Automatically learns URL scheme to app token mappings through usage

### 2. Timing Modes
- **Default Mode**: 10-second delay before blocking
- **Random Mode**: 1-10 second random delay before blocking
- User can switch between modes in settings

### 3. Blocking Workflow
1. User tries to open blocked app (triggers Intent via Shortcuts)
2. Intent temporarily unblocks the app and foregrounds Second Thought
3. Continue screen shows with app-specific messaging
4. User taps "Continue to App" → opens target app
5. Timer starts (10 seconds or random 1-10 seconds)
6. App gets blocked again for 10 minutes
7. Automatic unblock after 10 minutes

### 4. State Management
- Persistent storage via `UserDefaults` for:
  - Selected apps configuration
  - Learned URL scheme → ApplicationToken mappings
  - Current blocking state and expiration times
  - Active timers and timing mode preferences
- Real-time blocking managed via `ManagedSettingsStore`

### 5. Intent Integration
- `ActivateSecondThoughtIntent` handles Shortcuts automation
- Prevents infinite loops with continue cooldown (3 seconds)
- Manages app unblocking and re-foregrounding logic

## Data Flow

### Blocking Cycle
```
App Launch Attempt → Shortcuts → Intent → Unblock → Foreground SecondThought → 
Continue Screen → Open Target App → Start Timer → Block App → 10min Timer → Auto Unblock
```

### Key State Variables
- `blockedApps: Set<ApplicationToken>` - Currently blocked applications
- `learnedSchemeToTokenMapping: [String: ApplicationToken]` - URL scheme to app mappings
- `blockExpirationTimes: [String: Date]` - When each app should be unblocked
- `activeTimers: [String: [DispatchWorkItem]]` - Active timer references

## Security & Permissions
- Requires Screen Time permissions (`family-controls` entitlement)
- Uses secure ApplicationToken system (opaque identifiers)
- All blocking operations validate authorization status

## Technical Implementation Notes
- Heavy use of `print()` statements for debugging/logging
- Defensive programming with state restoration on app launch
- Timer management with cleanup for expired blocks
- Thread-safe operations using `@MainActor` and main queue dispatch

## Target Use Case
Digital wellness tool for users who want to reduce impulsive social media usage while still allowing intentional access with friction/delay.