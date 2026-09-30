import CoachCore
import CoachUI
import SwiftData
import SwiftUI
import WidgetKit

struct AddHabitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let nextSortOrder: Int

    @State private var name = ""
    @State private var symbol = Self.symbols[0]
    @State private var tint: HabitTint = .teal

    static let symbols = [
        "checkmark.circle", "drop.fill", "book.fill", "figure.flexibility", "brain.head.profile", "moon.zzz.fill",
        "leaf.fill", "bed.double.fill", "pills.fill", "fork.knife", "pencil.and.scribble", "music.note",
    ]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Drink 2L water", text: $name)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onSubmit(save)
                }
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(Self.symbols, id: \.self) { item in
                            Button {
                                symbol = item
                            } label: {
                                Image(systemName: item)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(symbol == item ? tint.color.opacity(0.2) : .clear, in: .circle)
                                    .foregroundStyle(symbol == item ? tint.color : .secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.replacingOccurrences(of: ".", with: " "))
                            .accessibilityAddTraits(symbol == item ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Colour") {
                    Picker("Colour", selection: $tint) {
                        ForEach(HabitTint.allCases, id: \.self) { tint in
                            Text(tint.rawValue.capitalized)
                                .foregroundStyle(tint.color)
                                .tag(tint)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", role: .confirm, action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        context.insert(Habit(name: trimmedName, symbolName: symbol, tint: tint, sortOrder: nextSortOrder))
        try? context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKinds.todayHabits)
        LiveCoachShortcuts.updateAppShortcutParameters()
        dismiss()
    }
}
