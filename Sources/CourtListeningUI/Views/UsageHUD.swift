import SwiftUI
import CourtListeningCore

/// Compact rate-limit heads-up display. Shows consumption against each rolling window and
/// turns amber/red as a window fills. Limits are advisory (server enforces via 429).
struct UsageHUD: View {
    let usage: APIUsage

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            meter("min", used: usage.requestsThisMinute, limit: usage.minuteLimit, atLimit: usage.isAtMinuteLimit)
            meter("hr", used: usage.requestsThisHour, limit: usage.hourLimit, atLimit: usage.isAtHourLimit)
            meter("day", used: usage.requestsThisDay, limit: usage.dayLimit, atLimit: usage.isAtDayLimit)
        }
        .padding(.horizontal, Design.Spacing.md)
        .padding(.vertical, Design.Spacing.sm)
        .background(Design.Color.surface)
    }

    private func meter(_ label: String, used: Int, limit: Int, atLimit: Bool) -> some View {
        let fraction = limit > 0 ? min(1, Double(used) / Double(limit)) : 0
        let color: Color = atLimit ? Design.Color.danger : (fraction >= 0.7 ? Design.Color.warning : Design.Color.ok)
        return VStack(alignment: .leading, spacing: Design.Spacing.xs) {
            HStack(spacing: Design.Spacing.xs) {
                Text(label).font(Design.Font.caption).foregroundStyle(Design.Color.secondaryText)
                Spacer(minLength: 0)
                Text("\(used)/\(limit)").font(Design.Font.mono)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Design.Color.separator)
                    Capsule().fill(color).frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: Design.Size.hudBarHeight)
        }
    }
}

#if DEBUG
#Preview("Usage HUD") {
    VStack {
        UsageHUD(usage: .initial)
        UsageHUD(usage: .initial.recording(at: Date()).recording(at: Date()).recording(at: Date()).recording(at: Date()))
    }
    .padding()
}
#endif
