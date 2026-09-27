import SwiftUI

/// The large time and date at the top of the lock screen. Updates on the minute.
struct ClockView: View {
    let metrics: LockScreenMetrics

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(spacing: 2 * metrics.layoutScale) {
                Text(context.date, format: .dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
                    .font(.system(size: metrics.clockFontSize, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: context.date)

                Text(context.date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: metrics.dateFontSize, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(context.date, format: .dateTime.hour().minute().weekday(.wide).month(.wide).day()))
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}
