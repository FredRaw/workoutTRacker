import SwiftUI
import SwiftData

struct StartedSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    let onSessionCompleted: (WorkoutSession) -> Void
    private let startedAt = Date()

    @State private var expandedExerciseID: PersistentIdentifier?
    @State private var runner = SessionRunner<PersistentIdentifier>()
    @State private var setTimerTaskByExercise: [PersistentIdentifier: Task<Void, Never>] = [:]
    @State private var restTimerTaskByExercise: [PersistentIdentifier: Task<Void, Never>] = [:]
    @State private var exerciseComments: [PersistentIdentifier: String] = [:]
    @State private var completedAt: Date?

    var body: some View {
        NavigationStack {
            List {
                sessionStartedSection

                Section("Exercises") {
                    if session.exercises.isEmpty {
                        Text("No exercises in this session.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(session.exercises) { exercise in
                            let isCompleted = isExerciseCompleted(exercise)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(exercise.exerciseName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    if isCompleted {
                                        Text("Completed")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: expandedExerciseID == exercise.persistentModelID ? "chevron.up" : "chevron.down")
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        toggleExpansion(for: exercise)
                                    }
                                }

                                if expandedExerciseID == exercise.persistentModelID {
                                    exerciseDetailView(for: exercise)
                                }
                            }
                            .padding(.vertical, 2)
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                            .opacity(isCompleted ? 0.6 : 1)
                        }
                    }
                }

                Section {
                    Button {
                        completeSession()
                    } label: {
                        Label("Session Complete", systemImage: "flag.checkered")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!allExercisesCompleted)
                }
            }
            .navigationTitle("Started Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        stopAllTimers()
                        dismiss()
                    }
                }
            }
            .onAppear {
                preloadExerciseComments()
            }
            .onDisappear {
                stopAllTimers()
            }
        }
    }

    private var sessionStartedSection: some View {
        Section("Session Started") {
            Text(session.name)
                .font(.headline)

            Text("Started: \(startedAt, format: .dateTime.hour().minute())")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let completedAt {
                Text("Completed: \(completedAt, format: .dateTime.hour().minute())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Completed: In progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TimelineView(.periodic(from: startedAt, by: 1)) { context in
                Text("Duration: \(durationText(at: context.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func exerciseDetailView(for exercise: WorkoutExercise) -> some View {
        let completedSets = runner.completedSets(for: exercise.persistentModelID)
        let isCompleted = isExerciseCompleted(exercise)

        VStack(alignment: .leading, spacing: 6) {
            Text(exercise.plannedSummary)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(
                "Exercise comment",
                text: bindingForComment(exercise),
                axis: .vertical
            )
            .lineLimit(2...4)
            .disabled(isCompleted)

            Text("Sets completed: \(completedSets)/\(exercise.sets)")
                .font(.caption)

            HStack {
                if !exercise.trackingMode.usesTime {
                    Button {
                        completeSet(for: exercise)
                    } label: {
                        Label("Set Performed", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(completedSets >= exercise.sets || isCompleted)
                } else {
                    Button {
                        startSetTimer(for: exercise)
                    } label: {
                        Label("Start Set", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        completedSets >= exercise.sets ||
                        isCompleted ||
                        isSetTimerRunning(for: exercise) ||
                        isRestTimerRunning(for: exercise)
                    )
                }

                Spacer()

                if runner.setRemaining(for: exercise.persistentModelID) > 0 {
                    Text("Set: \(runner.setRemaining(for: exercise.persistentModelID))s")
                        .font(.caption)
                        .fontWeight(.semibold)
                } else if runner.restRemaining(for: exercise.persistentModelID) > 0 {
                    Text("Rest: \(runner.restRemaining(for: exercise.persistentModelID))s")
                        .font(.caption)
                        .fontWeight(.semibold)
                } else if isCompleted {
                    Text("Rest: Finished")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Rest: Ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                if !exercise.trackingMode.usesTime {
                    Button("Start Rest Timer") {
                        startRestTimer(for: exercise)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isCompleted)
                }

                Button("Stop") {
                    stopTimers(for: exercise)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isCompleted || (!isSetTimerRunning(for: exercise) && !isRestTimerRunning(for: exercise)))
            }
        }
    }

    private func preloadExerciseComments() {
        guard exerciseComments.isEmpty else {
            return
        }

        for exercise in session.exercises {
            exerciseComments[exercise.persistentModelID] = exercise.notes
        }
    }

    private func bindingForComment(_ exercise: WorkoutExercise) -> Binding<String> {
        Binding(
            get: {
                exerciseComments[exercise.persistentModelID] ?? ""
            },
            set: { newValue in
                exerciseComments[exercise.persistentModelID] = newValue
            }
        )
    }

    private func durationText(at currentDate: Date) -> String {
        let endDate = completedAt ?? currentDate
        let totalSeconds = max(0, Int(endDate.timeIntervalSince(startedAt)))

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var allExercisesCompleted: Bool {
        guard !session.exercises.isEmpty else {
            return false
        }
        return session.exercises.allSatisfy { isExerciseCompleted($0) }
    }

    private func completeSession() {
        let completionDate = Date()
        completedAt = completionDate

        for exercise in session.exercises {
            let comment = (exerciseComments[exercise.persistentModelID] ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            exercise.notes = comment
        }

        session.completedDurationSeconds = max(0, Int(completionDate.timeIntervalSince(startedAt)))

        stopAllTimers()
        onSessionCompleted(session)
        dismiss()
    }

    private func toggleExpansion(for exercise: WorkoutExercise) {
        let id = exercise.persistentModelID
        if expandedExerciseID == id {
            expandedExerciseID = nil
        } else {
            expandedExerciseID = id
        }
    }

    private func isExerciseCompleted(_ exercise: WorkoutExercise) -> Bool {
        runner.isExerciseCompleted(id: exercise.persistentModelID, totalSets: exercise.sets)
    }

    private func isSetTimerRunning(for exercise: WorkoutExercise) -> Bool {
        runner.hasRunningSetTimer.contains(exercise.persistentModelID)
    }

    private func isRestTimerRunning(for exercise: WorkoutExercise) -> Bool {
        runner.hasRunningRestTimer.contains(exercise.persistentModelID)
    }

    private func completeSet(for exercise: WorkoutExercise) {
        let id = exercise.persistentModelID
        runner.incrementSet(for: id, totalSets: exercise.sets)
        startRestTimer(for: exercise)
    }

    private func startSetTimer(for exercise: WorkoutExercise) {
        let id = exercise.persistentModelID
        guard runner.completedSets(for: id) < exercise.sets else {
            return
        }

        stopSetTimer(for: exercise)
        runner.setSetRemaining(for: id, seconds: max(exercise.durationSeconds, 0))
        runner.setSetTimerRunning(true, for: id)

        setTimerTaskByExercise[id] = Task {
            while !Task.isCancelled {
                guard runner.setRemaining(for: id) > 0 else {
                    break
                }

                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled {
                    break
                }

                await MainActor.run {
                    let current = runner.setRemaining(for: id)
                    if current > 0 {
                        runner.setSetRemaining(for: id, seconds: current - 1)
                    }
                }
            }

            await MainActor.run {
                setTimerTaskByExercise[id] = nil
                runner.setSetTimerRunning(false, for: id)

                if runner.setRemaining(for: id) == 0 {
                    runner.incrementSet(for: id, totalSets: exercise.sets)
                    startRestTimer(for: exercise)
                }
            }
        }
    }

    private func startRestTimer(for exercise: WorkoutExercise) {
        let id = exercise.persistentModelID
        stopRestTimer(for: exercise)

        runner.setRestRemaining(for: id, seconds: exercise.restSeconds)
        runner.setRestTimerRunning(true, for: id)

        restTimerTaskByExercise[id] = Task {
            while !Task.isCancelled {
                guard runner.restRemaining(for: id) > 0 else {
                    break
                }

                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled {
                    break
                }

                await MainActor.run {
                    let current = runner.restRemaining(for: id)
                    if current > 0 {
                        runner.setRestRemaining(for: id, seconds: current - 1)
                    }
                }
            }

            await MainActor.run {
                restTimerTaskByExercise[id] = nil
                runner.setRestTimerRunning(false, for: id)
            }
        }
    }

    private func stopTimers(for exercise: WorkoutExercise) {
        stopSetTimer(for: exercise)
        stopRestTimer(for: exercise)
    }

    private func stopSetTimer(for exercise: WorkoutExercise) {
        let id = exercise.persistentModelID
        setTimerTaskByExercise[id]?.cancel()
        setTimerTaskByExercise[id] = nil
        runner.setSetTimerRunning(false, for: id)
        runner.setSetRemaining(for: id, seconds: 0)
    }

    private func stopRestTimer(for exercise: WorkoutExercise) {
        let id = exercise.persistentModelID
        restTimerTaskByExercise[id]?.cancel()
        restTimerTaskByExercise[id] = nil
        runner.setRestTimerRunning(false, for: id)
        runner.setRestRemaining(for: id, seconds: 0)
    }

    private func stopAllTimers() {
        for (id, task) in setTimerTaskByExercise {
            task.cancel()
            runner.setSetTimerRunning(false, for: id)
            runner.setSetRemaining(for: id, seconds: 0)
        }
        for (id, task) in restTimerTaskByExercise {
            task.cancel()
            runner.setRestTimerRunning(false, for: id)
            runner.setRestRemaining(for: id, seconds: 0)
        }
        setTimerTaskByExercise.removeAll()
        restTimerTaskByExercise.removeAll()
    }
}
