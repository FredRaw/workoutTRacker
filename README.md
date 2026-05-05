# Workout Tracker

Workout Tracker is an iOS SwiftUI app for planning and logging strength and recovery sessions.

## Features

- Weekly plan view with current week number.
- Session creation options:
  - Create new strength session
  - Create recovery session
  - Choose from session library
- Session library templates for reusing workouts.
- Exercise-level tracking:
  - Sets and reps
  - Weight (kg)
  - Time counter (seconds)
  - Tracking mode: Weight, Time, or Both
  - RIR
  - Rest timer (seconds)
- Insight view with:
  - Personal records
  - Progress chart
  - Overview stats
  - Workout history

## Tech Stack

- SwiftUI
- SwiftData
- Charts
- Testing framework

## Project Structure

- `myPersonalWorkoutPlan/ContentView.swift`: Main screen, weekly plan, add-session flow.
- `myPersonalWorkoutPlan/InsightView.swift`: Insights and workout history.
- `myPersonalWorkoutPlan/Item.swift`: SwiftData models (`WorkoutSession`, `WorkoutExercise`, templates).
- `myPersonalWorkoutPlan/WeeklyPlan.swift`: Weekly plan domain models and defaults.
- `myPersonalWorkoutPlan/WorkoutAnalytics.swift`: Analytics/query logic used by Insight.
- `myPersonalWorkoutPlanTests/`: Unit tests.

## Requirements

- Xcode 15+
- iOS 17+

## Run

1. Open `myPersonalWorkoutPlan.xcodeproj` in Xcode.
2. Select the `myPersonalWorkoutPlan` scheme.
3. Build and run on a simulator or device.

## Tests

Current tests are located in:

- `myPersonalWorkoutPlanTests/WorkoutAnalyticsTests.swift`
- `myPersonalWorkoutPlanTests/SessionTemplateTests.swift`

If tests do not appear in the test navigator, ensure the test files are part of a test target and included in the active test plan.

## Data Storage

Data is persisted locally using SwiftData.

## License

No license file is currently included.
