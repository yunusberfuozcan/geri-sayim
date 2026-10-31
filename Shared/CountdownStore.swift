import Foundation
import SwiftUI
#if os(iOS)
import WidgetKit
#endif

let tr = Locale(identifier: "tr_TR")

// MARK: - Senkronlanan veri (Mac ↔ iPhone, iCloud anahtar-değer deposu)

struct Countdown: Codable, Equatable {
    var title: String
    var target: Date
    var updatedAt: Date

    static let placeholder = Countdown(
        title: "Önemli Gün",
        target: Calendar.current.date(byAdding: .day, value: 30, to: Calendar.current.startOfDay(for: Date()))!,
        updatedAt: .distantPast)
}

enum CountdownSync {
    static let key = "countdown"
    static let appGroup = "group.com.berfu.gerisayim"

    /// iPhone'da widget ile paylaşılan yerel kopya; Mac'te uygulamanın kendi ayarları.
    static var local: UserDefaults {
        #if os(iOS)
        UserDefaults(suiteName: appGroup) ?? .standard
        #else
        .standard
        #endif
    }

    static func decode(_ data: Data?) -> Countdown? {
        data.flatMap { try? JSONDecoder().decode(Countdown.self, from: $0) }
    }

    /// iCloud ve yerel kopyadan en son güncelleneni döner.
    static func load() -> Countdown? {
        let cloud = decode(NSUbiquitousKeyValueStore.default.data(forKey: key))
        let cached = decode(local.data(forKey: key))
        switch (cloud, cached) {
        case let (c?, l?): return c.updatedAt >= l.updatedAt ? c : l
        case let (c, l): return c ?? l
        }
    }

    static func save(_ c: Countdown) {
        guard let data = try? JSONEncoder().encode(c) else { return }
        local.set(data, forKey: key)
        NSUbiquitousKeyValueStore.default.set(data, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
        reloadWidgets()
    }

    static func reloadWidgets() {
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

final class CountdownStore: ObservableObject {
    static let shared = CountdownStore()

    @Published var title: String { didSet { persist() } }
    @Published var target: Date { didSet { persist() } }
    let isFirstRun: Bool
    private var applyingRemote = false

    init() {
        NSUbiquitousKeyValueStore.default.synchronize()
        var c = CountdownSync.load()
        // Senkron öncesi Mac sürümünün kayıtlarını taşı
        let d = UserDefaults.standard
        if c == nil, let oldTarget = d.object(forKey: "target") as? Date {
            c = Countdown(title: d.string(forKey: "title") ?? Countdown.placeholder.title, target: oldTarget, updatedAt: Date())
            CountdownSync.save(c!)
        }
        isFirstRun = c == nil
        title = (c ?? .placeholder).title
        target = (c ?? .placeholder).target

        NotificationCenter.default.addObserver(
            self, selector: #selector(cloudChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default)
    }

    private func persist() {
        guard !applyingRemote else { return }
        CountdownSync.save(Countdown(title: title, target: target, updatedAt: Date()))
    }

    @objc private func cloudChanged(_ note: Notification) {
        DispatchQueue.main.async { self.refresh() }
    }

    /// Başka cihazdan gelen değişikliği uygular.
    func refresh() {
        guard let c = CountdownSync.load(), c.title != title || c.target != target else { return }
        applyingRemote = true
        title = c.title
        target = c.target
        applyingRemote = false
        if let data = try? JSONEncoder().encode(c) { CountdownSync.local.set(data, forKey: CountdownSync.key) }
        CountdownSync.reloadWidgets()
    }
}

// MARK: - Kalan süre hesabı (Mac kartı, iPhone uygulaması ve widget ortak kullanır)

struct Remaining {
    let days: Int, hours: Int, minutes: Int, seconds: Int
    let isOver: Bool

    init(from now: Date, to target: Date) {
        let total = max(0, Int(target.timeIntervalSince(now).rounded(.down)))
        isOver = total == 0
        days = total / 86400
        hours = total % 86400 / 3600
        minutes = total % 3600 / 60
        seconds = total % 60
    }
}

extension Date {
    var trFormatted: String {
        formatted(.dateTime.day().month(.wide).year().hour().minute().locale(tr))
    }
}
