import CoachCore
import CoachUI
import SwiftUI

struct HealthCard: View {
    @Environment(HealthModel.self) private var health

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Activity", systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(.pink)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .coachCard()
    }

    @ViewBuilder
    private var content: some View {
        switch health.state {
        case .unknown, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 80)
        case .unsupported:
            Text("Apple Health isn't available on this device.")
                .foregroundStyle(.secondary)
        case .needsAccess:
            VStack(alignment: .leading, spacing: 10) {
                Text("""
                    Connect Apple Health so the coach can factor in your steps and active energy. \
                    LiveCoach only reads data; it never writes.
                    """)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Connect Apple Health", systemImage: "heart.text.square") {
                    Task { await health.connect() }
                }
                .buttonStyle(.bordered)
                .tint(.pink)
            }
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        case .loaded(let week):
            if week.allSatisfy({ $0.steps == 0 && $0.activeEnergy == 0 }) {
                ContentUnavailableView(
                    "No activity yet",
                    systemImage: "figure.walk.motion",
                    description: Text("Steps and active energy from the last 7 days will show up here once Apple Health has data.")
                )
            } else {
                loaded(week)
            }
        }
    }

    private func loaded(_ week: [DailyActivity]) -> some View {
        let today = week.last
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                StatTile(title: "Steps today", value: (today?.steps ?? 0).formatted(), symbol: "shoeprints.fill", tint: .green)
                StatTile(title: "Active kcal", value: (today?.activeEnergy ?? 0).formatted(), symbol: "flame.fill", tint: .orange)
            }
            ActivityBarChart(activity: week)
                .frame(height: 120)
        }
    }
}
