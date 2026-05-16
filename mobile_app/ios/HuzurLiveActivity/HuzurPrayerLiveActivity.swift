import ActivityKit
import WidgetKit
import SwiftUI

struct HuzurPrayerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HuzurPrayerAttributes.self) { context in
            Link(destination: URL(string: context.state.deepLink)!) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(context.attributes.title).font(.caption.bold())
                    Text(context.state.nextPrayerName).font(.title2.bold())
                    Text("\(context.state.nextPrayerTime) • \(context.state.remainingMinutes) dk").font(.caption)
                }
                .padding()
            }
            .activityBackgroundTint(Color(red: 0.02, green: 0.24, blue: 0.21))
            .activitySystemActionForegroundColor(Color(red: 0.89, green: 0.71, blue: 0.35))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.nextPrayerName).font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.nextPrayerTime).font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.state.remainingMinutes) dakika kaldı")
                        .font(.caption)
                }
            } compactLeading: {
                Text(context.state.nextPrayerName.prefix(1))
            } compactTrailing: {
                Text(context.state.nextPrayerTime)
            } minimal: {
                Text("HV")
            }
            .widgetURL(URL(string: context.state.deepLink))
        }
    }
}
