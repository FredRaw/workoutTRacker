import Foundation

struct PlannedSession: Identifiable {
    let id = UUID()
    let day: Weekday
    let name: String
    let plannedExercises: String
}

enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    init?(from date: Date) {
        let component = Calendar.current.component(.weekday, from: date)
        self.init(rawValue: component)
    }
}

enum WeeklyPlanTemplate {
    static let defaultPlan: [PlannedSession] = [
        PlannedSession(day: .sunday, name: "Recovery", plannedExercises: "Mobility, Light Cardio"),
        PlannedSession(day: .monday, name: "Push Day", plannedExercises: "Bench Press, Overhead Press, Triceps"),
        PlannedSession(day: .tuesday, name: "Lower Technique", plannedExercises: "Front Squat, Lunges, Core"),
        PlannedSession(day: .wednesday, name: "Pull Day", plannedExercises: "Deadlift, Barbell Row, Biceps"),
        PlannedSession(day: .thursday, name: "Conditioning", plannedExercises: "Sled Push, Carries, Intervals"),
        PlannedSession(day: .friday, name: "Leg Day", plannedExercises: "Squat, Romanian Deadlift, Calves"),
        PlannedSession(day: .saturday, name: "Upper Hypertrophy", plannedExercises: "Incline Press, Pulldown, Shoulders")
    ]
}
