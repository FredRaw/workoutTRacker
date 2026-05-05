//
//  ContentView.swift
//  myPersonalWorkoutPlan
//
//  Created by Fredrik Rawicki on 05/05/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    @Query(sort: [SortDescriptor(\SessionTemplate.name)]) private var sessionTemplates: [SessionTemplate]

    @State private var isShowingAddSession = false
    @State private var isShowingSessionLibrary = false
    @State private var isShowingAddOptions = false
    @State private var sessionCreationMode: SessionCreationMode = .strength

    private let plannedSessions = WeeklyPlanTemplate.defaultPlan

    var body: some View {
        NavigationStack {
            List {
                weeklyPlanSection

                Section {
                    NavigationLink {
                        InsightView()
                    } label: {
                        Label("Open Insights", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }
            .navigationTitle("Workout Tracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddOptions = true
                    } label: {
                        Label("New Session", systemImage: "plus")
                    }
                }
            }
            .confirmationDialog("Add Session", isPresented: $isShowingAddOptions, titleVisibility: .visible) {
                Button("Create New Strength Session") {
                    sessionCreationMode = .strength
                    isShowingAddSession = true
                }

                Button("Create Recovery Session") {
                    sessionCreationMode = .recovery
                    isShowingAddSession = true
                }

                Button("Choose From Session Library") {
                    isShowingSessionLibrary = true
                }

                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $isShowingAddSession) {
                AddSessionView(mode: sessionCreationMode) { newSession, saveToLibrary in
                    modelContext.insert(newSession)

                    if saveToLibrary {
                        let template = SessionTemplate(
                            name: newSession.name,
                            notes: newSession.notes,
                            exercises: newSession.exercises.map {
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
                        modelContext.insert(template)
                    }
                }
            }
            .sheet(isPresented: $isShowingSessionLibrary) {
                SessionLibraryPickerView(templates: sessionTemplates) { template in
                    let newSession = template.makeWorkoutSession(date: .now)
                    modelContext.insert(newSession)
                }
            }
        }
    }

    private var weeklyPlanSection: some View {
        Section {
            ForEach(plannedSessions) { plan in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.day.title)
                            .font(.headline)
                        Spacer()
                        Text(plan.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(displayLine(for: plan))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            HStack {
                Text("Weekly Plan")
                Spacer()
                Text("Week \(Calendar.current.component(.weekOfYear, from: .now))")
            }
        }
    }

    private func displayLine(for plan: PlannedSession) -> String {
        let names = sessions
            .filter { Weekday(from: $0.date) == plan.day }
            .map(\.name)

        if names.isEmpty {
            return plan.plannedExercises
        }
        return names.joined(separator: ", ")
    }
}

private struct SessionLibraryPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let templates: [SessionTemplate]
    let onSelect: (SessionTemplate) -> Void

    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Library Sessions",
                        systemImage: "books.vertical",
                        description: Text("Create a new session and enable 'Save to Session Library'.")
                    )
                } else {
                    ForEach(templates) { template in
                        Button {
                            onSelect(template)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.headline)
                                Text(template.exercises.map(\.exerciseName).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Session Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private enum SessionCreationMode: Equatable {
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

private struct AddSessionView: View {
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
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Exercise name", text: $draft.exerciseName)
                                    .textInputAutocapitalization(.words)

                                Stepper("Sets: \(draft.sets)", value: $draft.sets, in: 1...20)
                                Stepper("Reps: \(draft.reps)", value: $draft.reps, in: 1...30)

                                Picker("Tracking", selection: $draft.trackingMode) {
                                    ForEach(ExerciseTrackingMode.allCases) { mode in
                                        Text(mode.title).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if draft.trackingMode == .weight || draft.trackingMode == .both {
                                    TextField("Weight (kg)", value: $draft.weight, format: .number.precision(.fractionLength(0...2)))
                                        .keyboardType(.decimalPad)
                                    Text("Enter weight in kg")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                if draft.trackingMode == .time || draft.trackingMode == .both {
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

    private func removeDraft(withID id: UUID) {
        drafts.removeAll { $0.id == id }
        if drafts.isEmpty {
            drafts = [ExerciseDraft()]
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, SessionTemplate.self, TemplateExercise.self], inMemory: true)
}
