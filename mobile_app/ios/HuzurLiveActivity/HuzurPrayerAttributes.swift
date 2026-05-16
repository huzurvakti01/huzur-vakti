import ActivityKit
import Foundation

struct HuzurPrayerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var nextPrayerName: String
        var nextPrayerTime: String
        var remainingMinutes: Int
        var deepLink: String
    }

    var title: String
}
