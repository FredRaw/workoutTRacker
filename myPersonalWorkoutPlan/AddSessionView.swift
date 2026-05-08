import SwiftUI

enum SessionCreationMode: Equatable {
    case strength
    case recovery

    var navigationTitle: String {
        switch self {
        case .strength:
            return "New Strength Session"
        case .recovery:
            return "New Recovery Session"
        }
    }

    var defaultName: String {
        switch self {
        case .strength:
            return ""
        case .recovery:
            return "Recovery Session"
        }
    }
}

private struct ExerciseDraft: Identifiable {
    let id = UUID()
    var exerciseName: String = ""
    var sets: Int = 3
    var reps: Int = 5
    var weight: Double = 0
    var durationSeconds: Int = 0
    var trackingMode: ExerciseTrackingMode = .weight
    var rir: Int = 2
    var restSeconds: Int = 60
    var notes: String = ""
}

struct AddSessionView: View {
    let mode: SessionCreationMode
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var sessionName: String
    @State private var sessionNotes = ""
    @State private var drafts: [ExerciseDraft] = [ExerciseDraft()]
    @State private var saveToLibrary = true

    let onSave: (WorkoutSession, Bool) -> Void

    init(mode: SessionCreationMode, onSave: @escaping (WorkoutSession, Bool) -> Void) {
        self.mode = mode
        self.onSave = onSave
        _sessionName = State(initialValue: mode.defaultName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("Session name", text: $sessionName)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Session notes (optional)", text: $sessionNotes, axis: .vertical)
                        .lineLimit(2...4)
                    Toggle("Save to Session Library", isOn: $saveToLibrary)
                }

                if mode == .strength {
                    Section("Exercises") {
                        ForEach($drafts) { $draft in
                            let index = indexForDraft(withID: draft.id)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Exercise \(index + 1)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Button {
                                        moveDraft(withID: draft.id, direction: .up)
                                    } label: {
                                        Image(systemName: "arrow.up")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(index == 0)

                                    Button {
                                        moveDraft(withID: draft.id, direction: .down)
                                    } label: {
                                        Image(systemName: "arrow.down")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(index == drafts.count - 1)
                                }

                                TextField("Exercise name", text: $draft.exerciseName)
                                    .textInputAutocapitalization(.words)

                                Stepper("Sets: \(draft.sets)", value: $draft.sets, in: 1...20)

                                Picker("Tracking", selection: $draft.trackingMode) {
                                    ForEach(ExerciseTrackingMode.allCases) { mode in
                                        Text(mode.title).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if draft.trackingMode.showsRepsInCreation {
                                    Stepper("Reps: \(draft.reps)", value: $draft.reps, in: 1...30)
                                }

                                if draft.trackingMode.usesWeight {
                                    TextField("Weight (kg)", value: $draft.weight, format: .number.precision(.fractionLength(0...2)))
                                        .keyboardType(.decimalPad)
                                    Text("Enter weight in kg")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                if draft.trackingMode.usesTime {
                                    Stepper("Counter: \(draft.durationSeconds) sec", value: $draft.durationSeconds, in: 0...7200, step: 1)
                                }

                                Stepper("RIR: \(draft.rir)", value: $draft.rir, in: 0...6)
                                Stepper("Rest Timer: \(draft.restSeconds) sec", value: $draft.restSeconds, in: 15...600, step: 15)

                                TextField("Notes (optional)", text: $draft.notes)

                                Button(role: .destructive) {
                                    removeDraft(withID: draft.id)
                                } label: {
                                    Text("Remove Exercise")
                                }
                                .disabled(drafts.count == 1)
                            }
                            .padding(.vertical, 4)
                        }

                        Button {
                            drafts.append(ExerciseDraft())
                        } label: {
                            Label("Add Exercise", systemImage: "plus.circle")
                        }
                    }
                }
            }
            .navigationTitle(mode.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanedNotes = sessionNotes.trimmingCharacters(in: .whitespacesAndNewlines)

                        let exercises: [WorkoutExercise] = drafts.compactMap { draft in
                            let cleanedExerciseName = draft.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !cleanedExerciseName.isEmpty else {
                                return nil
                            }

                            return WorkoutExercise(
                                exerciseName: cleanedExerciseName,
                                sets: draft.sets,
                                reps: draft.reps,
                                weight: draft.weight,
                                durationSeconds: draft.durationSeconds,
                                trackingMode: draft.trackingMode,
                                rir: draft.rir,
                                restSeconds: draft.restSeconds,
                                notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        }

                        let session = WorkoutSession(
                            date: date,
                            name: cleanedName,
                            notes: cleanedNotes,
                            exercises: exercises
                        )

                        onSave(session, saveToLibrary)
                        dismiss()
                    }
                    .disabled(!canSaveSession)
                }
            }
        }
    }

    private var canSaveSession: Bool {
        let cleanedName = sessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            return false
        }

        if mode == .recovery {
            return true
        }

        return drafts.contains {
            !$0.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private enum MoveDirection {
        case up
        case down
    }

    private func indexForDraft(withID id: UUID) -> Int {
        drafts.firstIndex { $0.id == id } ?? 0
    }

    private func moveDraft(withID id: UUID, direction: MoveDirection) {
        guard let sourceIndex = drafts.firstIndex(where: { $0.id == id }) else {
            return
        }

        let destinationIndex: Int
        switch direction {
        case .up:
            destinationIndex = sourceIndex - 1
        case .down:
            destinationIndex = sourceIndex + 1
        }

        guard drafts.indices.contains(destinationIndex) else {
            return
        }

        drafts.swapAt(sourceIndex, destinationIndex)
    }

    private func removeDraft(withID id: UUID) {
        drafts.removeAll { $0.id == id }
        if drafts.isEmpty {
            drafts = [ExerciseDraft()]
        }
    }
}
