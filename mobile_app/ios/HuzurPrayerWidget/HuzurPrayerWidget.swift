import WidgetKit
import SwiftUI

struct PrayerEntry: TimelineEntry {
    let date: Date
    let name: String
    let time: String
    let remaining: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: Date(), name: "Akşam", time: "19:41", remaining: "82")
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        completion(Timeline(entries: [readEntry()], policy: .after(Date().addingTimeInterval(1800))))
    }

    private func readEntry() -> PrayerEntry {
        let defaults = UserDefaults(suiteName: "group.com.huzurvakti.app")
        return PrayerEntry(
            date: Date(),
            name: defaults?.string(forKey: "nextPrayerName") ?? "Namaz",
            time: defaults?.string(forKey: "nextPrayerTime") ?? "--:--",
            remaining: defaults?.string(forKey: "remainingMinutes") ?? "--"
        )
    }
}

struct HuzurPrayerWidgetView: View {
    var entry: PrayerEntry

    var body: some View {
        Link(destination: URL(string: "huzurvakti://widget/open")!) {
            ZStack {
                LinearGradient(colors: [Color(red: 0.02, green: 0.24, blue: 0.21), Color(red: 0.05, green: 0.49, blue: 0.40)], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(alignment: .leading) {
                    Text("Huzur Vakti").font(.caption.bold()).foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text(entry.name).font(.title3.bold()).foregroundStyle(Color(red: 0.89, green: 0.71, blue: 0.35))
                    Text(entry.time).font(.title.bold()).foregroundStyle(.white)
                    Text("\(entry.remaining) dk kaldı").font(.caption).foregroundStyle(.white.opacity(0.72))
                }.padding()
            }
        }
    }
}

@main
struct HuzurPrayerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HuzurPrayerWidget", provider: Provider()) { entry in
            HuzurPrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Huzur Vakti")
        .description("Sıradaki namaz vaktini gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
