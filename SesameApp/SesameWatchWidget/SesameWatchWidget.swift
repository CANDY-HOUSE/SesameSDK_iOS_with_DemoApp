import SwiftUI
import WidgetKit

@main
struct SesameWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SesameComplication", provider: SesameComplicationProvider()) { _ in
            SesameComplicationView()
        }
        .configurationDisplayName("Sesame")
        .description("Tap to open")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    }
}

struct SesameComplicationEntry: TimelineEntry {
    let date: Date
}

struct SesameComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> SesameComplicationEntry {
        SesameComplicationEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SesameComplicationEntry) -> Void) {
        completion(SesameComplicationEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SesameComplicationEntry>) -> Void) {
        completion(Timeline(entries: [SesameComplicationEntry(date: Date())], policy: .never))
    }
}

struct SesameComplicationView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .complicationBackground()
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCorner:
            icon
                .widgetLabel("Sesame")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Sesame")
                    .font(.headline)
                    .foregroundColor(Color(red: 0x28 / 255, green: 0xae / 255, blue: 0xb1 / 255))
                    .widgetAccentable()
                Text("Tap to open")
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Text("Sesame")
        default:
            icon
        }
    }

    private var iconSuffix: String {
        family == .accessoryCorner ? "Small" : ""
    }

    private var icon: some View {
        iconImage
            .scaledToFit()
            .clipShape(Circle())
    }

    @ViewBuilder
    private var iconImage: some View {
        let image = Image("ComplicationColor" + iconSuffix).resizable()
        if #available(watchOS 11.0, *) {
            image.widgetAccentedRenderingMode(.desaturated)
        } else {
            image
        }
    }
}

private extension View {
    @ViewBuilder
    func complicationBackground() -> some View {
        if #available(watchOS 10.0, *) {
            containerBackground(for: .widget) {
                Color.clear
            }
        } else {
            self
        }
    }
}
