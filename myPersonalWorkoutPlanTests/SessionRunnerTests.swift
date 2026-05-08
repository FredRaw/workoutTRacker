import Testing
@testable import myPersonalWorkoutPlan

struct SessionRunnerTests {
    @Test
    func incrementSetStopsAtPlannedSetCount() {
        var runner = SessionRunner<String>()

        runner.incrementSet(for: "squat", totalSets: 2)
        runner.incrementSet(for: "squat", totalSets: 2)
        runner.incrementSet(for: "squat", totalSets: 2)

        #expect(runner.completedSets(for: "squat") == 2)
    }

    @Test
    func exerciseIsNotCompletedWhenRestTimerRunning() {
        var runner = SessionRunner<String>()

        runner.incrementSet(for: "bench", totalSets: 1)
        runner.setRestRemaining(for: "bench", seconds: 30)
        runner.setRestTimerRunning(true, for: "bench")

        #expect(!runner.isExerciseCompleted(id: "bench", totalSets: 1))

        runner.setRestTimerRunning(false, for: "bench")
        runner.setRestRemaining(for: "bench", seconds: 0)

        #expect(runner.isExerciseCompleted(id: "bench", totalSets: 1))
    }

    @Test
    func stopTimersClearsTimerFlagsAndRemainingSeconds() {
        var runner = SessionRunner<String>()

        runner.setSetTimerRunning(true, for: "plank")
        runner.setRestTimerRunning(true, for: "plank")
        runner.setSetRemaining(for: "plank", seconds: 45)
        runner.setRestRemaining(for: "plank", seconds: 60)

        runner.stopTimers(for: "plank")

        #expect(runner.setRemaining(for: "plank") == 0)
        #expect(runner.restRemaining(for: "plank") == 0)
        #expect(!runner.hasRunningSetTimer.contains("plank"))
        #expect(!runner.hasRunningRestTimer.contains("plank"))
    }
}
