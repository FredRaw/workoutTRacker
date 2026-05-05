import Foundation
import SwiftData

struct ExerciseProgressPoint: Identifiable {
    let id: PersistentIdentifier
    let date: Date
    let exercise: String
    let weight: Double
}

struct WorkoutAnalytics {
    let sessions: [WorkoutSession]

    private var allExercises: [WorkoutExercise] {
        sessions.flatMap(\.exercises)
    }

    var totalVolume: Double {
        sessions.reduce(0) { $0 + $1.estimatedVolume }
    }

    var exerciseOptions: [String] {
        ["All"] + Set(allExercises.map(\.exerciseName)).sorted()
    }

    var personalRecords: [(exercise: String, weight: Double)] {
        var bestByExercise: [String: Double] = [:]
        for exercise in allExercises {
            let currentBest = bestByExercise[exercise.exerciseName] ?? 0
            bestByExercise[exercise.exerciseName] = max(currentBest, exercise.weight)
        }
        return bestByExercise
            .map { (exercise: $0.key, weight: $0.value) }
            .sorted { $0.exercise < $1.exercise }
    }

    func filteredSessions(for exercise: String) -> [WorkoutSession] {
        guard exercise != "All" else {
            return sessions
        }
        return sessions.filter { session in
            session.exercises.contains(where: { $0.exerciseName == exercise })
        }
    }

    func progressPoints(for exercise: String) -> [ExerciseProgressPoint] {
        let points = allExercises.compactMap { workoutExercise -> ExerciseProgressPoint? in
            guard let sessionDate = workoutExercise.session?.date else {
                return nil
            }
            if exercise != "All" && workoutExercise.exerciseName != exercise {
                return nil
            }
            return ExerciseProgressPoint(
                id: workoutExercise.persistentModelID,
                date: sessionDate,
                exercise: workoutExercise.exerciseName,
                weight: workoutExercise.weight
            )
        }
        return points.sorted { $0.date < $1.date }
    }
}
