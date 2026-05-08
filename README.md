# Workout Tracker

Workout Tracker is an iOS SwiftUI app for planning, performing, and reviewing strength and recovery training sessions.

## Current Features

- Weekly plan with:
  - Current week number
  - Sunday -> Saturday ordering
  - Expand/collapse per day
  - Collapsed preview and expanded management view
  - Remove planned sessions from expanded day view
  - Completed sessions marked as completed and blocked from restarting
- Session creation flow:
  - Pick from Session Library
  - Create new strength session
  - Create new recovery session
  - Name/notes/date for session
  - Save to library toggle
  - Exercise reordering (move up/down before save)
- Exercise setup:
  - Tracking mode: Weight, Time, Both
  - Weight input with kg helper text
  - Time counter with 1-second increments
  - Reps shown only for Weight mode
  - Sets, RIR, and adjustable rest timer
  - Exercise notes/comments
- Started session flow:
  - Session started view with live duration
  - Expand exercise rows to perform sets
  - Time-based sets use set timer, then auto-start rest timer
  - Manual set completion for non-time exercises
  - Stop active timers
  - Exercise auto-completion state (grayed out when done)
  - Session complete action when all exercises are completed
  - Completion timestamp and duration persisted
- Insight view:
  - Personal records
  - Progress
  - Overview
  - Workout history including completed sessions

## Architecture Notes

- SwiftData models in `Item.swift`
- Weekly planning domain in `WeeklyPlan.swift`
- Analytics logic in `WorkoutAnalytics.swift`
- Session execution state logic extracted to `SessionRunner.swift`
- SwiftUI views split by feature (`ContentView`, `AddSessionView`, `StartedSessionView`, `InsightView`, weekly plan section views)

## Tech Stack

- SwiftUI
- SwiftData
- Charts
- Apple Testing framework (`import Testing`)

## Requirements

- Xcode 16+
- iOS 18+ deployment target (check project settings if changed)

## Run Locally

1. Open `myPersonalWorkoutPlan.xcodeproj` in Xcode.
2. Select the `myPersonalWorkoutPlan` scheme.
3. Build and run on simulator or device.

## Test Files

- `myPersonalWorkoutPlanTests/WorkoutAnalyticsTests.swift`
- `myPersonalWorkoutPlanTests/SessionTemplateTests.swift`
- `myPersonalWorkoutPlanTests/SessionRunnerTests.swift`

Note: if Xcode reports `0 tests`, verify test target membership and active test plan configuration.

## Data Persistence

All sessions and related entities are stored locally using SwiftData.
