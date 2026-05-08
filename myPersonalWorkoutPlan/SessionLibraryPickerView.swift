import SwiftUI

struct SessionLibraryPickerView: View {
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
