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
    @State private var expandedDay: Weekday?
    @State private var startedSession: WorkoutSession?

    private let plannedSessions = WeeklyPlanTemplate.defaultPlan

    var body: some View {
        NavigationStack {
            List {
                WeeklyPlanSectionView(
                    plannedSessions: plannedSessions,
                    sessions: sessions,
                    expandedDay: $expandedDay,
                    onDeleteSession: { session in
                        withAnimation {
                            modelContext.delete(session)
                        }
                    },
                    onStartSession: { session in
                        startedSession = session
                    }
                )

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
                        modelContext.insert(newSession.asTemplate())
                    }
                }
            }
            .sheet(isPresented: $isShowingSessionLibrary) {
                SessionLibraryPickerView(templates: sessionTemplates) { template in
                    let newSession = template.makeWorkoutSession(date: .now)
                    modelContext.insert(newSession)
                }
            }
            .sheet(item: $startedSession) { session in
                StartedSessionView(session: session) { completedSession in
                    completedSession.status = .completed
                }
            }
        }
    }

}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, WorkoutExercise.self, SessionTemplate.self, TemplateExercise.self], inMemory: true)
}
