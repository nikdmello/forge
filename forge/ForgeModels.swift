import Foundation

struct DomainProgress: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var totalSeconds: Int

    init(id: UUID = UUID(), name: String, icon: String, totalSeconds: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.totalSeconds = totalSeconds
    }
}

enum ForgeProgression {
    static let baseLevelXP = 30

    static func xp(forSeconds seconds: Int) -> Int {
        max(0, seconds / 60)
    }

    static func totalXP(for domains: [DomainProgress]) -> Int {
        xp(forSeconds: domains.reduce(0) { $0 + $1.totalSeconds })
    }

    static func xpRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return baseLevelXP * Int(pow(2.0, Double(level - 2)))
    }

    static func level(forXP xp: Int) -> Int {
        var remaining = max(0, xp)
        var level = 1
        while remaining >= xpRequired(forLevel: level + 1) {
            remaining -= xpRequired(forLevel: level + 1)
            level += 1
        }
        return level
    }

    static func progressToNextLevel(forXP xp: Int) -> Double {
        let level = level(forXP: xp)
        let required = xpRequired(forLevel: level + 1)
        guard required > 0 else { return 0 }

        var used = max(0, xp)
        if level >= 2 {
            for currentLevel in 2...level {
                used -= xpRequired(forLevel: currentLevel)
            }
        }
        return min(1, max(0, Double(used) / Double(required)))
    }
}

enum ForgeStorage {
    static let domainsKey = "forge.domains.v1"
    static let selectedDomainIDKey = "forge.selectedDomainID.v1"
}

enum ForgeDefaults {
    static let domains: [DomainProgress] = [
        DomainProgress(name: "LeetCode", icon: "brain.head.profile"),
        DomainProgress(name: "App Dev", icon: "hammer.fill"),
        DomainProgress(name: "Gym", icon: "figure.strengthtraining.traditional"),
        DomainProgress(name: "Reading", icon: "book.fill"),
        DomainProgress(name: "Career Prep", icon: "briefcase.fill"),
        DomainProgress(name: "Mental Health", icon: "heart.fill")
    ]
}
