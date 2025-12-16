import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct SnipEntry: TimelineEntry {
    let date: Date
    let snipData: Data?
    let snipDate: Date?
    let snipCount: Int
    let configuration: ConfigurationAppIntent
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Snipbook"
    static var description = IntentDescription("Display your snips")

    @Parameter(title: "Show Date", default: true)
    var showDate: Bool
}

// MARK: - Timeline Provider

struct SnipbookTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SnipEntry {
        SnipEntry(
            date: Date(),
            snipData: nil,
            snipDate: nil,
            snipCount: 0,
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SnipEntry {
        // Return sample data for preview
        SnipEntry(
            date: Date(),
            snipData: nil,
            snipDate: Date(),
            snipCount: 12,
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SnipEntry> {
        // Fetch latest snip from shared container
        let entry = await fetchLatestSnip(configuration: configuration)

        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchLatestSnip(configuration: ConfigurationAppIntent) async -> SnipEntry {
        // In real implementation, fetch from App Group shared container
        // For now, return placeholder
        return SnipEntry(
            date: Date(),
            snipData: nil,
            snipDate: nil,
            snipCount: 0,
            configuration: configuration
        )
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: SnipEntry

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.98, green: 0.96, blue: 0.93)

            if let snipData = entry.snipData,
               let image = UIImage(data: snipData) {
                // Show snip
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(12)
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "scissors")
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0.82, green: 0.48, blue: 0.36))

                    Text("Snipbook")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: SnipEntry

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.98, green: 0.96, blue: 0.93)

            HStack(spacing: 16) {
                // Snip preview
                if let snipData = entry.snipData,
                   let image = UIImage(data: snipData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 120)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 2, y: 2)
                } else {
                    // Placeholder stamp
                    StampPlaceholder()
                        .frame(width: 100, height: 120)
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Snipbook")
                        .font(.system(size: 17, weight: .semibold))

                    if entry.configuration.showDate, let snipDate = entry.snipDate {
                        Text(snipDate, style: .date)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "scissors")
                            .font(.system(size: 11))
                        Text("\(entry.snipCount) snips")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(16)
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: SnipEntry

    var body: some View {
        ZStack {
            // Background - paper texture
            Color(red: 0.98, green: 0.96, blue: 0.93)

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Snipbook")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Little Moments, Cut & Kept")
                            .font(.system(size: 12, design: .serif))
                            .italic()
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "scissors")
                            .font(.system(size: 12))
                        Text("\(entry.snipCount)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(red: 0.82, green: 0.48, blue: 0.36))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Snips area
                if let snipData = entry.snipData,
                   let image = UIImage(data: snipData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 2, y: 3)
                        .rotationEffect(.degrees(-2))
                } else {
                    // Empty state with shapes preview
                    EmptyLargeWidgetView()
                }

                Spacer()

                // Footer
                if entry.configuration.showDate, let snipDate = entry.snipDate {
                    Text("Last snip: \(snipDate, style: .relative) ago")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 12)
                }
            }
        }
    }
}

// MARK: - Helper Views

struct StampPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.91, green: 0.72, blue: 0.62))

            // Perforations
            VStack {
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { _ in
                        Circle()
                            .fill(Color(red: 0.98, green: 0.96, blue: 0.93))
                            .frame(width: 6, height: 6)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { _ in
                        Circle()
                            .fill(Color(red: 0.98, green: 0.96, blue: 0.93))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.vertical, 2)

            // Scissors icon
            Image(systemName: "scissors")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct EmptyLargeWidgetView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Shape icons
            HStack(spacing: 20) {
                ShapeIcon(systemName: "stamp", label: "Stamp")
                ShapeIcon(systemName: "circle", label: "Circle")
                ShapeIcon(systemName: "ticket", label: "Ticket")
            }

            Text("Tap to add your first snip")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
}

struct ShapeIcon: View {
    let systemName: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemName)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.82, green: 0.48, blue: 0.36))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Widget Definition

struct SnipbookWidget: Widget {
    let kind: String = "SnipbookWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: SnipbookTimelineProvider()
        ) { entry in
            SnipbookWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Snipbook")
        .description("See your latest snips at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SnipbookWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SnipEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct SnipbookWidgetBundle: WidgetBundle {
    var body: some Widget {
        SnipbookWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    SnipbookWidget()
} timeline: {
    SnipEntry(date: Date(), snipData: nil, snipDate: nil, snipCount: 0, configuration: ConfigurationAppIntent())
    SnipEntry(date: Date(), snipData: nil, snipDate: Date(), snipCount: 12, configuration: ConfigurationAppIntent())
}

#Preview("Medium", as: .systemMedium) {
    SnipbookWidget()
} timeline: {
    SnipEntry(date: Date(), snipData: nil, snipDate: Date(), snipCount: 24, configuration: ConfigurationAppIntent())
}

#Preview("Large", as: .systemLarge) {
    SnipbookWidget()
} timeline: {
    SnipEntry(date: Date(), snipData: nil, snipDate: Date(), snipCount: 42, configuration: ConfigurationAppIntent())
}
