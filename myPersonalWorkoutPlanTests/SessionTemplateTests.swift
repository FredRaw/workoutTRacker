import Testing
@testable import myPersonalWorkoutPlan

struct SessionTemplateTests {
    @Test
    func makeWorkoutSessionCopiesExercisesAndFields() {
        let template = SessionTemplate(
            name: "Push Day",
            notes: "Heavy focus",
            exercises: [
                TemplateExercise(
                    exerciseName: "Bench Press",
                    sets: 4,
                    reps: 6,
                    weight: 85,
                    durationSeconds: 0,
                    trackingMode: .weight,
                    rir: 2,
                    restSeconds: 120,
                    notes: "Pause first rep"
                )
            ]
        )

        let created = template.makeWorkoutSession()

        #expect(created.name == "Push Day")
        #expect(created.notes == "Heavy focus")
        #expect(created.exercises.count == 1)

        let copiedExercise = created.exercises[0]
        #expect(copiedExercise.exerciseName == "Bench Press")
        #expect(copiedExercise.weight == 85)
        #expect(copiedExercise.rir == 2)
        #expect(copiedExercise.restSeconds == 120)
        #expect(copiedExercise.trackingMode == .weight)
    }
}
