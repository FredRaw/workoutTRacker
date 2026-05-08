//
//  Item.swift
//  myPersonalWorkoutPlan
//
//  Created by Fredrik Rawicki on 05/05/2026.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date
    var name: String
    var notes: String
    var statusRawValue: String
    var completedDurationSeconds: Int

    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.session)
    var exercises: [WorkoutExercise]

    init(
        date: Date = .now,
        name: String,
        notes: String = "",
        status: SessionStatus = .planned,
        completedDurationSeconds: Int = 0,
        exercises: [WorkoutExercise] = []
    ) {
        self.date = date
        self.name = name
        self.notes = notes
        self.statusRawValue = status.rawValue
        self.completedDurationSeconds = completedDurationSeconds
        self.exercises = exercises
    }

    var estimatedVolume: Double {
        exercises.reduce(0) { $0 + $1.estimatedVolume }
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRawValue) ?? .planned }
        set { statusRawValue = newValue.rawValue }
    }
}

@Model
final class WorkoutExercise {
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: Double
    var durationSeconds: Int
    var trackingModeRawValue: String
    var rir: Int
    var restSeconds: Int
    var notes: String

    var session: WorkoutSession?

    init(
        exerciseName: String,
        sets: Int,
        reps: Int,
        weight: Double,
        durationSeconds: Int = 0,
        trackingMode: ExerciseTrackingMode = .weight,
        rir: Int = 2,
        restSeconds: Int = 60,
        notes: String = "",
        session: WorkoutSession? = nil
    ) {
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.durationSeconds = durationSeconds
        self.trackingModeRawValue = trackingMode.rawValue
        self.rir = rir
        self.restSeconds = restSeconds
        self.notes = notes
        self.session = session
    }

    var estimatedVolume: Double {
        weight * Double(sets * reps)
    }

    var trackingMode: ExerciseTrackingMode {
        get { ExerciseTrackingMode(rawValue: trackingModeRawValue) ?? .weight }
        set { trackingModeRawValue = newValue.rawValue }
    }
}

@Model
final class SessionTemplate {
    var name: String
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise]

    init(name: String, notes: String = "", exercises: [TemplateExercise] = []) {
        self.name = name
        self.notes = notes
        self.exercises = exercises
    }
}

@Model
final class TemplateExercise {
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: Double
    var durationSeconds: Int
    var trackingModeRawValue: String
    var rir: Int
    var restSeconds: Int
    var notes: String

    var template: SessionTemplate?

    init(
        exerciseName: String,
        sets: Int,
        reps: Int,
        weight: Double,
        durationSeconds: Int = 0,
        trackingMode: ExerciseTrackingMode = .weight,
        rir: Int = 2,
        restSeconds: Int = 60,
        notes: String = "",
        template: SessionTemplate? = nil
    ) {
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.durationSeconds = durationSeconds
        self.trackingModeRawValue = trackingMode.rawValue
        self.rir = rir
        self.restSeconds = restSeconds
        self.notes = notes
        self.template = template
    }

    var trackingMode: ExerciseTrackingMode {
        get { ExerciseTrackingMode(rawValue: trackingModeRawValue) ?? .weight }
        set { trackingModeRawValue = newValue.rawValue }
    }
}

enum SessionStatus: String, CaseIterable {
    case planned
    case completed
}

enum ExerciseTrackingMode: String, CaseIterable, Identifiable {
    case weight
    case time
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weight: return "Weight"
        case .time: return "Time"
        case .both: return "Both"
        }
    }

    var usesWeight: Bool {
        self == .weight || self == .both
    }

    var usesTime: Bool {
        self == .time || self == .both
    }

    var showsRepsInCreation: Bool {
        self == .weight
    }
}

extension WorkoutExercise {
    var historySummary: String {
        switch trackingMode {
        case .weight:
            return "\(sets)x\(reps) @ \(String(format: "%.1f", weight)) kg"
        case .time:
            return "\(sets)x\(reps) • \(durationSeconds) sec"
        case .both:
            return "\(sets)x\(reps) @ \(String(format: "%.1f", weight)) kg • \(durationSeconds) sec"
        }
    }

    var plannedSummary: String {
        "Planned: \(historySummary) • Rest \(restSeconds)s"
    }
}

extension WorkoutSession {
    var completedDurationText: String {
        guard completedDurationSeconds > 0 else {
            return ""
        }

        let hours = completedDurationSeconds / 3600
        let minutes = (completedDurationSeconds % 3600) / 60
        let seconds = completedDurationSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func asTemplate() -> SessionTemplate {
        SessionTemplate(
            name: name,
            notes: notes,
            exercises: exercises.map {
                TemplateExercise(
                    exerciseName: $0.exerciseName,
                    sets: $0.sets,
                    reps: $0.reps,
                    weight: $0.weight,
                    durationSeconds: $0.durationSeconds,
                    trackingMode: $0.trackingMode,
                    rir: $0.rir,
                    restSeconds: $0.restSeconds,
                    notes: $0.notes
                )
            }
        )
    }

    func completionCopy(date: Date = .now) -> WorkoutSession {
        WorkoutSession(
            date: date,
            name: name,
            notes: notes,
            exercises: exercises.map {
                WorkoutExercise(
                    exerciseName: $0.exerciseName,
                    sets: $0.sets,
                    reps: $0.reps,
                    weight: $0.weight,
                    durationSeconds: $0.durationSeconds,
                    trackingMode: $0.trackingMode,
                    rir: $0.rir,
                    restSeconds: $0.restSeconds,
                    notes: $0.notes
                )
            }
        )
    }
}

extension SessionTemplate {
    func makeWorkoutSession(date: Date = .now) -> WorkoutSession {
        let copiedExercises = exercises.map {
            WorkoutExercise(
                exerciseName: $0.exerciseName,
                sets: $0.sets,
                reps: $0.reps,
                weight: $0.weight,
                durationSeconds: $0.durationSeconds,
                trackingMode: $0.trackingMode,
                rir: $0.rir,
                restSeconds: $0.restSeconds,
                notes: $0.notes
            )
        }

        return WorkoutSession(
            date: date,
            name: name,
            notes: notes,
            exercises: copiedExercises
        )
    }
}
