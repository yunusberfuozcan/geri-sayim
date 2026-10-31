import SwiftUI

@main
struct GeriSayimApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, tr)
        }
        .onChange(of: scenePhase) { _, phase in
            // Uygulama öne gelince Mac'te yapılan değişikliği hemen al
            if phase == .active {
                NSUbiquitousKeyValueStore.default.synchronize()
                CountdownStore.shared.refresh()
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var countdown = CountdownStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        CountdownCard(title: countdown.title, target: countdown.target, now: ctx.date)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                Section {
                    TextField("Başlık", text: $countdown.title)
                    DatePicker("Tarih ve saat", selection: $countdown.target,
                               displayedComponents: [.date, .hourAndMinute])
                } footer: {
                    Text("Değişiklikler iCloud ile Mac'teki geri sayıma da yansır. Ana ekrana eklemek için boş bir yere basılı tut → Düzenle → Widget Ekle → Geri Sayım.")
                }
            }
            .navigationTitle("Geri Sayım")
        }
    }
}

struct CountdownCard: View {
    let title: String
    let target: Date
    let now: Date

    var body: some View {
        let r = Remaining(from: now, to: target)
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
            if r.isOver {
                Text("🎉 Geldi!")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(r.days)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("gün").font(.system(size: 22, weight: .medium, design: .rounded))
                }
                Text(String(format: "%02d sa  %02d dk  %02d sn", r.hours, r.minutes, r.seconds))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }
            Text(target.trFormatted)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
