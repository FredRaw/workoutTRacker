import Testing
@testable import myPersonalWorkoutPlan

struct WorkoutAnalyticsTests {
    @Test
    func personalRecordsUseHighestWeightPerExercise() {
        let sessions = [
            WorkoutSession(
                name: "A",
                exercises: [
                    WorkoutExercise(exerciseName: "Squat", sets: 3, reps: 5, weight: 100),
                    WorkoutExercise(exerciseName: "Bench", sets: 3, reps: 5, weight: 70)
                ]
            ),
            WorkoutSession(
                name: "B",
                exercises: [
                    WorkoutExercise(exerciseName: "Squat", sets: 3, reps: 5, weight: 110),
                    WorkoutExercise(exerciseName: "Bench", sets: 3, reps: 5, weight: 67.5)
                ]
            )
        ]

        let analytics = WorkoutAnalytics(sessions: sessions)

        #expect(analytics.personalRecords.count == 2)
        #expect(analytics.personalRecords.first(where: { $0.exercise == "Squat" })?.weight == 110)
        #expect(analytics.personalRecords.first(where: { $0.exercise == "Bench" })?.weight == 70)
    }

    @Test
    func exerciseFilterReturnsOnlyMatchingSessions() {
        let squat = WorkoutExercise(exerciseName: "Squat", sets: 3, reps: 5, weight: 100)
        let bench = WorkoutExercise(exerciseName: "Bench", sets: 3, reps: 5, weight: 70)

        let sessions = [
            WorkoutSession(name: "Lower", exercises: [squat]),
            WorkoutSession(name: "Upper", exercises: [bench])
        ]

        let analytics = WorkoutAnalytics(sessions: sessions)
        let filtered = analytics.filteredSessions(for: "Squat")

        #expect(filtered.count == 1)
        #expect(filtered.first?.name == "Lower")
    }
}
