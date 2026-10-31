import AppKit
import SwiftUI

let tr = Locale(identifier: "tr_TR")

// MARK: - Ayarlar (UserDefaults'ta saklanır)

final class Store: ObservableObject {
    static let shared = Store()
    private let d = UserDefaults.standard

    @Published var title: String { didSet { d.set(title, forKey: "title") } }
    @Published var target: Date { didSet { d.set(target, forKey: "target") } }
    @Published var showSeconds: Bool { didSet { d.set(showSeconds, forKey: "showSeconds") } }
    @Published var launchAtLogin: Bool { didSet { d.set(launchAtLogin, forKey: "launchAtLogin"); LoginAgent.apply(launchAtLogin) } }
    let isFirstRun: Bool

    init() {
        isFirstRun = d.object(forKey: "target") == nil
        title = d.string(forKey: "title") ?? "Önemli Gün"
        target = d.object(forKey: "target") as? Date
            ?? Calendar.current.date(byAdding: .day, value: 30, to: Calendar.current.startOfDay(for: Date()))!
        showSeconds = d.object(forKey: "showSeconds") as? Bool ?? true
        launchAtLogin = d.object(forKey: "launchAtLogin") as? Bool ?? false
        if launchAtLogin { LoginAgent.apply(true) }
    }
}

// MARK: - Mac açılınca başlatma (LaunchAgent)

enum LoginAgent {
    static let label = "com.berfu.gerisayim"
    static var url: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static func apply(_ enabled: Bool) {
        if enabled {
            guard let exe = Bundle.main.executablePath else { return }
            let plist: [String: Any] = ["Label": label, "ProgramArguments": [exe], "RunAtLoad": true]
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            (plist as NSDictionary).write(to: url, atomically: true)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - Masaüstü widget görünümü

struct CountdownView: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            content(now: ctx.date)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(width: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contextMenu {
            Button("Geri sayımı ayarla…") { AppDelegate.shared.openSettings() }
            Divider()
            Button("Çıkış") { NSApp.terminate(nil) }
        }
    }

    @ViewBuilder
    func content(now: Date) -> some View {
        let total = Int(store.target.timeIntervalSince(now).rounded(.down))
        VStack(spacing: 6) {
            Text(store.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if total > 0 {
                let days = total / 86400, h = total % 86400 / 3600, m = total % 3600 / 60, s = total % 60
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(days)")
                        .font(.system(size: 58, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("gün").font(.system(size: 20, weight: .medium, design: .rounded))
                }
                Text(store.showSeconds
                     ? String(format: "%02d sa  %02d dk  %02d sn", h, m, s)
                     : String(format: "%02d sa  %02d dk", h, m))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .monospacedDigit()
            } else {
                Text("🎉 Geldi!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .padding(.vertical, 8)
            }
            Text(store.target.formatted(.dateTime.day().month(.wide).year().hour().minute().locale(tr)))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ayarlar penceresi

struct SettingsView: View {
    @ObservedObject var store = Store.shared

    var body: some View {
        Form {
            TextField("Başlık", text: $store.title)
            DatePicker("Tarih ve saat", selection: $store.target, displayedComponents: [.date, .hourAndMinute])
            Toggle("Saniyeleri göster", isOn: $store.showSeconds)
            Toggle("Mac açılınca başlat", isOn: $store.launchAtLogin)
            HStack {
                Spacer()
                Button("Tamam") { NSApp.keyWindow?.close() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .environment(\.locale, tr)
        .padding(20)
        .frame(width: 380)
    }
}

// MARK: - Uygulama

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    var widget: NSWindow!
    var settings: NSWindow?
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ note: Notification) {
        let host = NSHostingView(rootView: CountdownView())
        host.setFrameSize(host.fittingSize)

        widget = NSWindow(contentRect: NSRect(origin: .zero, size: host.fittingSize),
                          styleMask: [.borderless], backing: .buffered, defer: false)
        widget.contentView = host
        widget.isOpaque = false
        widget.backgroundColor = .clear
        widget.hasShadow = true
        widget.isMovableByWindowBackground = true
        // Masaüstü ikonlarının hemen üstünde, tüm normal pencerelerin altında durur
        widget.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        widget.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        if !widget.setFrameUsingName("GeriSayimWidget"), let screen = NSScreen.main {
            let v = screen.visibleFrame
            widget.setFrameTopLeftPoint(NSPoint(x: v.maxX - widget.frame.width - 40, y: v.maxY - 40))
        }
        widget.setFrameAutosaveName("GeriSayimWidget")
        widget.orderFront(nil)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⏳"
        let menu = NSMenu()
        menu.addItem(withTitle: "Geri sayımı ayarla…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Çıkış", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        if Store.shared.isFirstRun { openSettings() }
    }

    @objc func openSettings() {
        if settings == nil {
            let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
            w.title = "Geri Sayım"
            w.contentView = NSHostingView(rootView: SettingsView())
            w.isReleasedWhenClosed = false
            w.center()
            settings = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settings?.makeKeyAndOrderFront(nil)
    }
}

let app = NSApplication.shared
app.delegate = AppDelegate.shared
app.run()
