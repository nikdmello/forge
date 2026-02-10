import Testing
@testable import forge

struct forgeTests {

    @Test func xpUsesOneMinutePerPoint() async throws {
        #expect(ForgeProgression.xp(forSeconds: 0) == 0)
        #expect(ForgeProgression.xp(forSeconds: 59) == 0)
        #expect(ForgeProgression.xp(forSeconds: 60) == 1)
        #expect(ForgeProgression.xp(forSeconds: 3600) == 60)
    }

    @Test func levelProgressionIsExponentialFromBase30() async throws {
        #expect(ForgeProgression.level(forXP: 0) == 1)
        #expect(ForgeProgression.level(forXP: 29) == 1)
        #expect(ForgeProgression.level(forXP: 30) == 2)
        #expect(ForgeProgression.level(forXP: 89) == 2)
        #expect(ForgeProgression.level(forXP: 90) == 3)
    }

    @Test func progressToNextLevelIsBounded() async throws {
        #expect(ForgeProgression.progressToNextLevel(forXP: 0) == 0)
        #expect(ForgeProgression.progressToNextLevel(forXP: 15) == 0.5)
        #expect(ForgeProgression.progressToNextLevel(forXP: 5000) <= 1)
        #expect(ForgeProgression.progressToNextLevel(forXP: -10) == 0)
    }

}
