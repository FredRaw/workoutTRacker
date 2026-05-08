import SwiftUI
import SwiftData
import Charts

struct InsightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]

    @State private var selectedExercise = "All"

    private var analytics: WorkoutAnalytics {
        WorkoutAnalytics(sessions: sessions)
    }

    private var filteredSessions: [WorkoutSession] {
        analytics.filteredSessions(for: selectedExercise)
    }

    private var chartEntries: [ExerciseProgressPoint] {
        analytics.progressPoints(for: selectedExercise)
    }

    var body: some View {
        List {
            personalRecordsSection
            progressChartSection
            overviewSection
            workoutHistorySection
        }
        .navigationTitle("Insight")
        .onChange(of: analytics.exerciseOptions) { _, newOptions in
            if !newOptions.contains(selectedExercise) {
                selectedExercise = "All"
            }
        }
    }

    private var personalRecordsSection: some View {
        Section("Personal Records") {
            if analytics.personalRecords.isEmpty {
                Text("No records yet. Add your first session.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(analytics.personalRecords, id: \.exercise) { record in
                    statRow(title: record.exercise, value: String(format: "%.1f kg", record.weight))
                }
            }
        }
    }

    private var progressChartSection: some View {
        Section("Progress") {
            Picker("Exercise", selection: $selectedExercise) {
                ForEach(analytics.exerciseOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.segmented)

            if chartEntries.isEmpty {
                Text("No data for selected exercise.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(chartEntries) { entry in
                    LineMark(x: .value("Date", entry.date), y: .value("Weight", entry.weight))
                        .foregroundStyle(by: .value("Exercise", entry.exercise))
                    PointMark(x: .value("Date", entry.date), y: .value("Weight", entry.weight))
                        .foregroundStyle(by: .value("Exercise", entry.exercise))
                }
                .frame(height: 180)
            }
        }
    }

    private var overviewSection: some View {
        Section("Overview") {
            statRow(title: "Logged Sessions", value: "\(sessions.count)")
            statRow(title: "Total Volume", value: "\(Int(analytics.totalVolume)) kg")
        }
    }

    private var workoutHistorySection: some View {
        Section("Workout History") {
            if filteredSessions.isEmpty {
                Text("No workouts logged for selected exercise.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredSessions) { session in
                    SessionHistoryRow(session: session, selectedExercise: selectedExercise)
                }
                .onDelete(perform: deleteFilteredSessions)
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func deleteFilteredSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredSessions[index])
            }
        }
    }
}

private struct SessionHistoryRow: View {
    let session: WorkoutSession
    let selectedExercise: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.name)
                    .font(.headline)
                Spacer()
                Text(session.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(session.exercises.filter { selectedExercise == "All" || $0.exerciseName == selectedExercise }) { exercise in
                ExerciseHistoryRow(exercise: exercise)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ExerciseHistoryRow: View {
    let exercise: WorkoutExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.exerciseName)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(exerciseSummary)
                .font(.caption)
            Text("RIR \(exercise.rir) • Rest \(exercise.restSeconds)s")
                .font(.caption2)
                .foregroundStyle(.secondary)
            if !exercise.notes.isEmpty {
                Text(exercise.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var exerciseSummary: String {
        exercise.historySummary
    }
}
