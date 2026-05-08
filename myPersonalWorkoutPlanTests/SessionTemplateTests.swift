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

    @Test
    func workoutSessionCanBeMappedToTemplate() {
        let session = WorkoutSession(
            name: "Conditioning",
            notes: "Intervals",
            exercises: [
                WorkoutExercise(
                    exerciseName: "Bike",
                    sets: 5,
                    reps: 1,
                    weight: 0,
                    durationSeconds: 60,
                    trackingMode: .time,
                    rir: 0,
                    restSeconds: 30,
                    notes: "Hard pace"
                )
            ]
        )

        let template = session.asTemplate()

        #expect(template.name == "Conditioning")
        #expect(template.notes == "Intervals")
        #expect(template.exercises.count == 1)
        #expect(template.exercises[0].trackingMode == .time)
        #expect(template.exercises[0].durationSeconds == 60)
    }

    @Test
    func completionCopyCreatesSeparateSessionInstance() {
        let original = WorkoutSession(
            name: "Leg Day",
            notes: "Heavy",
            exercises: [
                WorkoutExercise(exerciseName: "Squat", sets: 3, reps: 5, weight: 100)
            ]
        )

        let copied = original.completionCopy()

        #expect(copied !== original)
        #expect(copied.name == original.name)
        #expect(copied.exercises.count == original.exercises.count)
        #expect(copied.exercises[0] !== original.exercises[0])
    }
}
