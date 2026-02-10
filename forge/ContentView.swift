import SwiftUI
import Combine

struct ContentView: View {
    @AppStorage(ForgeStorage.domainsKey) private var storedDomainsData = ""
    @AppStorage(ForgeStorage.selectedDomainIDKey) private var storedSelectedDomainID = ""

    @State private var domains: [DomainProgress] = []
    @State private var selectedDomainID: UUID?
    @State private var isRunning = false
    @State private var sessionStart: Date?
    @State private var now = Date()
    @State private var newDomainName = ""

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var selectedDomain: DomainProgress? {
        guard let selectedDomainID else { return nil }
        return domains.first(where: { $0.id == selectedDomainID })
    }

    private var sessionSeconds: Int {
        guard isRunning, let sessionStart else { return 0 }
        return max(0, Int(now.timeIntervalSince(sessionStart)))
    }

    private var totalXP: Int {
        ForgeProgression.totalXP(for: domainsWithLiveSession)
    }

    private var overallLevel: Int {
        ForgeProgression.level(forXP: totalXP)
    }

    private var overallProgress: Double {
        ForgeProgression.progressToNextLevel(forXP: totalXP)
    }

    private var domainsWithLiveSession: [DomainProgress] {
        guard isRunning, let selectedDomainID else { return domains }
        return domains.map { domain in
            guard domain.id == selectedDomainID else { return domain }
            var updated = domain
            updated.totalSeconds += sessionSeconds
            return updated
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.06, green: 0.06, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topHeader
                    sessionPanel
                    domainStrip
                    addDomainPanel
                }
                .padding(18)
            }
        }
        .onAppear(perform: loadState)
        .onReceive(timer) { tick in
            now = tick
        }
    }

    private var topHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FORGE")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Level \(overallLevel) • \(totalXP) XP")
                .font(.headline)
                .foregroundStyle(.green)
            ProgressView(value: overallProgress)
                .tint(.green)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var sessionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(selectedDomain?.name ?? "Choose a domain")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(formatSeconds(sessionSeconds))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text("+\(ForgeProgression.xp(forSeconds: sessionSeconds)) session XP")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Button(action: toggleSession) {
                HStack {
                    Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    Text(isRunning ? "Stop Session" : "Start Session")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isRunning ? Color.red : Color.green)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedDomainID == nil)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var domainStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Domains")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(domainsWithLiveSession) { domain in
                        let xp = ForgeProgression.xp(forSeconds: domain.totalSeconds)
                        let level = ForgeProgression.level(forXP: xp)
                        let isSelected = domain.id == selectedDomainID

                        Button {
                            selectDomain(domain.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: domain.icon)
                                    .font(.title3)
                                Text(domain.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text("L\(level) • \(xp) XP")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .frame(width: 150, alignment: .leading)
                            .background(isSelected ? Color.green.opacity(0.25) : Color.white.opacity(0.06))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.green : Color.white.opacity(0.15), lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var addDomainPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add Domain")
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                TextField("New domain", text: $newDomainName)
                    .textFieldStyle(.roundedBorder)
                Button("Add", action: addDomain)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(newDomainName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func toggleSession() {
        guard let selectedDomainID else { return }

        if isRunning {
            commitSession(for: selectedDomainID)
        } else {
            sessionStart = now
            isRunning = true
        }
    }

    private func selectDomain(_ domainID: UUID) {
        if isRunning, let selectedDomainID {
            commitSession(for: selectedDomainID)
        }
        selectedDomainID = domainID
        storedSelectedDomainID = domainID.uuidString
    }

    private func addDomain() {
        let cleaned = newDomainName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        domains.append(DomainProgress(name: cleaned, icon: "star.fill"))
        newDomainName = ""
        saveDomains()
    }

    private func commitSession(for domainID: UUID) {
        guard let sessionStart else { return }
        let elapsed = max(0, Int(now.timeIntervalSince(sessionStart)))
        if let index = domains.firstIndex(where: { $0.id == domainID }) {
            domains[index].totalSeconds += elapsed
            saveDomains()
        }
        isRunning = false
        self.sessionStart = nil
    }

    private func loadState() {
        if let restored = loadDomains(), !restored.isEmpty {
            domains = restored
        } else {
            domains = ForgeDefaults.domains
            saveDomains()
        }

        if let uuid = UUID(uuidString: storedSelectedDomainID), domains.contains(where: { $0.id == uuid }) {
            selectedDomainID = uuid
        } else {
            selectedDomainID = domains.first?.id
            storedSelectedDomainID = selectedDomainID?.uuidString ?? ""
        }
    }

    private func loadDomains() -> [DomainProgress]? {
        guard let data = storedDomainsData.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([DomainProgress].self, from: data)
    }

    private func saveDomains() {
        guard let data = try? JSONEncoder().encode(domains), let encoded = String(data: data, encoding: .utf8) else {
            return
        }
        storedDomainsData = encoded
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}

#Preview {
    ContentView()
}
