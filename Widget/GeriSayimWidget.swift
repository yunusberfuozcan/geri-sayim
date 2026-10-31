import SwiftUI
import WidgetKit

struct Entry: TimelineEntry {
    let date: Date
    let countdown: Countdown
    /// Bu girişte gösterilen gün sayısı, `dayEnd` anında bir azalır.
    let days: Int
    let dayEnd: Date
    var isOver: Bool { date >= countdown.target }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { entries(for: .placeholder, from: Date())[0] }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(entries(for: current(), from: Date())[0])
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date()
        // Mac'te yapılan değişikliği yakalamak için yarım saatte bir yeniden oku
        completion(Timeline(entries: entries(for: current(), from: now), policy: .after(now.addingTimeInterval(30 * 60))))
    }

    private func current() -> Countdown {
        NSUbiquitousKeyValueStore.default.synchronize()
        return CountdownSync.load() ?? .placeholder
    }

    /// Her gün sınırında (hedef − k×24 sa) yeni bir giriş; arada saat/dakika/saniye canlı akar.
    func entries(for c: Countdown, from now: Date) -> [Entry] {
        var result: [Entry] = []
        var date = now
        for _ in 0..<8 {
            let r = Remaining(from: date, to: c.target)
            if r.isOver {
                result.append(Entry(date: max(date, c.target), countdown: c, days: 0, dayEnd: c.target))
                break
            }
            let dayEnd = c.target.addingTimeInterval(-Double(r.days) * 86400)
            result.append(Entry(date: date, countdown: c, days: r.days, dayEnd: dayEnd))
            date = dayEnd
        }
        return result
    }
}

struct WidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: Entry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.isOver ? "🎉 \(entry.countdown.title)" : "\(entry.days) gün · \(entry.countdown.title)")
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(entry.isOver ? "🎉" : "\(entry.days)").font(.system(size: 22, weight: .bold, design: .rounded))
                Text("gün").font(.caption2)
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.countdown.title).font(.headline).lineLimit(1)
                if entry.isOver {
                    Text("🎉 Geldi!")
                } else {
                    Text("\(entry.days) gün").font(.system(.title3, design: .rounded).bold())
                    timer.font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(spacing: 4) {
                Text(entry.countdown.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                if entry.isOver {
                    Text("🎉 Geldi!").font(.system(size: 30, weight: .bold, design: .rounded))
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(entry.days)")
                            .font(.system(size: family == .systemSmall ? 46 : 54, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text("gün").font(.system(size: 17, weight: .medium, design: .rounded))
                    }
                    timer.font(.system(size: 15, weight: .medium, design: .rounded))
                }
                if family != .systemSmall {
                    Text(entry.countdown.target.trFormatted).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Gün sınırına kalan süre, sistem tarafından saniye saniye güncellenir.
    private var timer: some View {
        Text(timerInterval: entry.date...entry.dayEnd, countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.center)
    }
}

@main
struct GeriSayimWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "GeriSayim", provider: Provider()) { entry in
            WidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Geri Sayım")
        .description("Önemli tarihine kalan süre. Mac ile senkron.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
