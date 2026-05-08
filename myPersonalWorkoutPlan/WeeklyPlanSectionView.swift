import SwiftUI

struct WeeklyPlanSectionView: View {
    let plannedSessions: [PlannedSession]
    let sessions: [WorkoutSession]
    @Binding var expandedDay: Weekday?
    let onDeleteSession: (WorkoutSession) -> Void
    let onStartSession: (WorkoutSession) -> Void

    var body: some View {
        Section {
            ForEach(plannedSessions) { plan in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(plan.day.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(plan.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: expandedDay == plan.day ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            if expandedDay == plan.day {
                                expandedDay = nil
                            } else {
                                expandedDay = plan.day
                            }
                        }
                    }

                    if expandedDay == plan.day {
                        expandedSessionsContent(for: plan)
                    } else {
                        Text(displayLine(for: plan))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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

    @ViewBuilder
    private func expandedSessionsContent(for plan: PlannedSession) -> some View {
        let daySessions = sessionsForDay(plan.day)

        if daySessions.isEmpty {
            Text("No logged sessions for this day.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(daySessions) { session in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.name)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Text(session.date, format: .dateTime.day().month().year().hour().minute())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if session.status == .completed && !session.completedDurationText.isEmpty {
                            Text("Completed in \(session.completedDurationText)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if session.status == .completed {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            onStartSession(session)
                        } label: {
                            Label("Start", systemImage: "play.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Button(role: .destructive) {
                        onDeleteSession(session)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sessionsForDay(_ day: Weekday) -> [WorkoutSession] {
        sessions.filter { Weekday(from: $0.date) == day }
    }

    private func displayLine(for plan: PlannedSession) -> String {
        let names = sessionsForDay(plan.day).map(\.name)
        if names.isEmpty {
            return "No logged sessions for this day."
        }
        return names.joined(separator: ", ")
    }
}
