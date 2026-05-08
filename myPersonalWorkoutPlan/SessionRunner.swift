import Foundation

struct SessionRunner<ExerciseID: Hashable> {
    private(set) var completedSets: [ExerciseID: Int] = [:]
    private(set) var setRemainingSeconds: [ExerciseID: Int] = [:]
    private(set) var restRemainingSeconds: [ExerciseID: Int] = [:]
    private(set) var hasRunningSetTimer: Set<ExerciseID> = []
    private(set) var hasRunningRestTimer: Set<ExerciseID> = []

    func completedSets(for id: ExerciseID) -> Int {
        completedSets[id] ?? 0
    }

    func setRemaining(for id: ExerciseID) -> Int {
        setRemainingSeconds[id] ?? 0
    }

    func restRemaining(for id: ExerciseID) -> Int {
        restRemainingSeconds[id] ?? 0
    }

    mutating func incrementSet(for id: ExerciseID, totalSets: Int) {
        let current = completedSets[id] ?? 0
        guard current < totalSets else {
            return
        }

        completedSets[id] = current + 1
    }

    mutating func setSetRemaining(for id: ExerciseID, seconds: Int) {
        setRemainingSeconds[id] = max(0, seconds)
    }

    mutating func setRestRemaining(for id: ExerciseID, seconds: Int) {
        restRemainingSeconds[id] = max(0, seconds)
    }

    mutating func setSetTimerRunning(_ isRunning: Bool, for id: ExerciseID) {
        if isRunning {
            hasRunningSetTimer.insert(id)
        } else {
            hasRunningSetTimer.remove(id)
        }
    }

    mutating func setRestTimerRunning(_ isRunning: Bool, for id: ExerciseID) {
        if isRunning {
            hasRunningRestTimer.insert(id)
        } else {
            hasRunningRestTimer.remove(id)
        }
    }

    mutating func stopTimers(for id: ExerciseID) {
        setSetTimerRunning(false, for: id)
        setRestTimerRunning(false, for: id)
        setSetRemaining(for: id, seconds: 0)
        setRestRemaining(for: id, seconds: 0)
    }

    mutating func isExerciseCompleted(id: ExerciseID, totalSets: Int) -> Bool {
        let setsCompleted = completedSets[id] ?? 0
        let setRemaining = setRemainingSeconds[id] ?? 0
        let restRemaining = restRemainingSeconds[id] ?? 0
        let runningSet = hasRunningSetTimer.contains(id)
        let runningRest = hasRunningRestTimer.contains(id)

        return setsCompleted >= totalSets && setRemaining == 0 && restRemaining == 0 && !runningSet && !runningRest
    }
}
