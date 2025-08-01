//
//  Profile.swift
//  Ostro-Eye
//
//  Created by Maxim Lanskoy on 28.07.2025.
//

import Foundation
import Fluent

struct Profile: Codable, Equatable {
    
    let name: String                 // Player name (including any emojis in the name)
    let level: Int                   // Player level
    let guild: String?               // Guild name and tag (if the player is in a guild)
    
    let currentHealth: Int           // Current health points
    let maxHealth: Int               // Maximum health points
    let healthRegenMinutes: Int?     // Minutes to full health regeneration (if health is not full)
    
    let currentEnergy: Int           // Current energy points
    let maxEnergy: Int               // Maximum energy points
    let energyRegenMinutes: Int?     // Minutes to next energy point (if energy is not full)
    
    let energySpentToday: Int        // Energy spent today
    
    let attack: Int                  // Attack stat
    let defense: Int                 // Defense stat
    let heroPower: Int               // Hero power (strength) stat
    
    let currentExperience: Int       // Current experience points towards next level
    let nextLevelExperience: Int     // Experience points required to reach the next level (threshold)
    
    let gold: Int                    // Gold amount
    
    let timestamp: Date              // Timestamp when this profile snapshot was taken (for history tracking)
    
    init?(from text: String, timestamp: Date) {
        // Split the text into lines, keeping empty lines for structure
        var lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Remove any completely empty lines (they are used just for spacing in the profile text)
        lines = lines.filter { !$0.isEmpty }
        guard !lines.isEmpty else { return nil }
        
        // 1. Parse Name and Level from the first line.
        let nameLine = lines[0]
        // The line format is: "⚔️ [Name] - Рівень [Level]"
        // Remove the "⚔️ " prefix if present:
        let nameLineStripped = nameLine.hasPrefix("⚔️")
            ? String(nameLine.dropFirst(2))  // drop the sword emoji and following space
            : nameLine
        // Find the " - Рівень " delimiter to separate name and level.
        guard let levelRange = nameLineStripped.range(of: " - Рівень ") else {
            return nil  // format unexpected
        }
        // Name is everything before " - Рівень"
        let nameString = String(nameLineStripped[..<levelRange.lowerBound])
        // Level number is everything after " - Рівень "
        let levelStart = levelRange.upperBound  // index right after the " - Рівень " substring
        let levelStr = nameLineStripped[levelStart...]
        guard let level = Int(levelStr) else {
            return nil
        }
        self.level = level
        self.name = nameString
        
        // 2. Parse Guild (if present).
        var guildName: String? = nil
        if lines.count > 1 && lines[1].contains("Гільдія:") {
            // The second line is a guild line.
            let guildLine = lines[1]
            if let guildInfoRange = guildLine.range(of: "Гільдія: ") {
                // Extract everything after "Гільдія: "
                guildName = String(guildLine[guildInfoRange.upperBound...])
            } else {
                guildName = String(guildLine.dropFirst("🏰 Гільдія: ".count))
            }
        }
        self.guild = guildName
        
        // Prepare to find lines by content (to handle optional guild line offset).
        func findLine(_ keyword: String) -> String? {
            return lines.first(where: { $0.contains(keyword) })
        }
        
        // 3. Parse Health.
        guard let healthLine = findLine("Здоров'я:") else { return nil }
        // Remove the "Здоров'я: " label to isolate the values.
        guard let healthLabelRange = healthLine.range(of: "Здоров'я: ") else { return nil }
        var healthValuesPart = healthLine[healthLabelRange.upperBound...]
        // Trim whitespace
        healthValuesPart = healthValuesPart.trimmingCharacters(in: .whitespaces)[...]
        // Check for a parenthesis indicating regen time.
        var healthRegenMin: Int? = nil
        if let parenIndex = healthValuesPart.firstIndex(of: "(") {
            // There is a regen time in parentheses.
            let regenText = healthValuesPart[parenIndex...]
            // Extract numeric time from inside the parentheses.
            if let closingParen = regenText.firstIndex(of: ")") {
                let insideParens = regenText[regenText.index(after: regenText.startIndex) ..< closingParen]
                healthRegenMin = Profile.parseTimeString(String(insideParens))
            }
            // Remove the parentheses part from the health values string.
            healthValuesPart = healthValuesPart[..<parenIndex].trimmingCharacters(in: .whitespaces)[...]
        }
        // Now healthValuesPart should be like "118/386" or "475/475"
        let healthParts = healthValuesPart.split(separator: "/")
        guard healthParts.count == 2,
              let currentHP = Int(healthParts[0]),
              let maxHP = Int(healthParts[1]) else {
            return nil
        }
        self.currentHealth = currentHP
        self.maxHealth = maxHP
        self.healthRegenMinutes = healthRegenMin
        
        // 4. Parse Energy.
        guard let energyLine = findLine("Енергія:") else { return nil }
        guard let energyLabelRange = energyLine.range(of: "Енергія: ") else { return nil }
        var energyValuesPart = energyLine[energyLabelRange.upperBound...]
        energyValuesPart = energyValuesPart.trimmingCharacters(in: .whitespaces)[...]
        var energyRegenMin: Int? = nil
        if let parenIndex = energyValuesPart.firstIndex(of: "(") {
            // Regen time for next energy point is present.
            let regenText = energyValuesPart[parenIndex...]
            if let closingParen = regenText.firstIndex(of: ")") {
                let insideParens = regenText[regenText.index(after: regenText.startIndex) ..< closingParen]
                energyRegenMin = Profile.parseTimeString(String(insideParens))
            }
            energyValuesPart = energyValuesPart[..<parenIndex].trimmingCharacters(in: .whitespaces)[...]
        }
        // energyValuesPart now like "3/10" or "0/10"
        let energyParts = energyValuesPart.split(separator: "/")
        guard energyParts.count == 2,
              let currentEN = Int(energyParts[0]),
              let maxEN = Int(energyParts[1]) else {
            return nil
        }
        self.currentEnergy = currentEN
        self.maxEnergy = maxEN
        self.energyRegenMinutes = energyRegenMin
        
        // 5. Parse energy spent today.
        guard let spentLine = findLine("Витрачено енергії за день:") else { return nil }
        if let colonIndex = spentLine.firstIndex(of: ":") {
            // Number is after the colon
            let valueStart = spentLine.index(colonIndex, offsetBy: 2)  // move past ":" and space
            let numberStr = spentLine[valueStart...].trimmingCharacters(in: .whitespaces)
            self.energySpentToday = Int(numberStr) ?? 0
        } else {
            self.energySpentToday = 0
        }
        
        // 6. Parse Attack, Defense, Hero Power.
        guard let attackLine = findLine("Атака:"),
              let defenseLine = findLine("Захист:"),
              let powerLine = findLine("Сила героя:") else {
            return nil
        }
        // Each of these lines has the format "[emoji] StatName: value"
        func parseStatValue(from line: String) -> Int? {
            guard let colonIdx = line.firstIndex(of: ":") else { return nil }
            var valueStart = line.index(after: colonIdx)
            // Skip any whitespace after the colon
            while valueStart < line.endIndex && line[valueStart].isWhitespace {
                valueStart = line.index(after: valueStart)
            }
            let valueStr = line[valueStart...]
            return Int(valueStr)
        }
        guard let atk = parseStatValue(from: attackLine),
              let def = parseStatValue(from: defenseLine),
              let pow = parseStatValue(from: powerLine) else {
            return nil
        }
        self.attack = atk
        self.defense = def
        self.heroPower = pow
        
        // 7. Parse Experience.
        guard let expLine = findLine("Досвід:") else { return nil }
        guard let expLabelRange = expLine.range(of: "Досвід: ") else { return nil }
        let expValuesPart = expLine[expLabelRange.upperBound...].trimmingCharacters(in: .whitespaces)
        // Format "currentXP/nextLevelXP"
        let expParts = expValuesPart.split(separator: "/")
        guard expParts.count == 2,
              let currentXP = Int(expParts[0]),
              let nextXP = Int(expParts[1]) else {
            return nil
        }
        self.currentExperience = currentXP
        self.nextLevelExperience = nextXP
        
        // 8. Parse Gold.
        guard let goldLine = findLine("Золото:") else { return nil }
        if let colonIndex = goldLine.firstIndex(of: ":") {
            let valueStart = goldLine.index(colonIndex, offsetBy: 2)  // after ": "
            let goldStr = goldLine[valueStart...].trimmingCharacters(in: .whitespaces)
            self.gold = Int(goldStr) ?? 0
        } else {
            self.gold = 0
        }
        
        // 9. Assign timestamp.
        self.timestamp = timestamp
    }
    
    /// Compare two player profiles and return a formatted string highlighting the differences.
    static func compareProfiles(old: Profile, new: Profile) -> String {
        var resultLines: [String] = []
        
        // Level comparison
        if new.level != old.level {
            resultLines.append("⚔️ Рівень: \(old.level) → \(new.level) \(new.level > old.level ? "⬆️" : "⬇️")")
        } else {
            resultLines.append("⚔️ Рівень: \(new.level) (без змін)")
        }
        
        // Experience comparison
        if new.level == old.level {
            // Same level: show XP progress difference
            let xpDiff = new.currentExperience - old.currentExperience
            let progressLine = "✨ Досвід: \(old.currentExperience)/\(old.nextLevelExperience) → \(new.currentExperience)/\(new.nextLevelExperience)"
            if xpDiff != 0 {
                let sign = xpDiff > 0 ? "+" : ""
                resultLines.append(progressLine + " (\(sign)\(xpDiff) XP)")
            } else {
                resultLines.append(progressLine + " (без змін)")
            }
        } else if new.level == old.level + 1 {
            // Leveled up once:
            let xpEarnedToLevel = old.nextLevelExperience - old.currentExperience  // XP to finish old level
            let xpInNewLevel = new.currentExperience
            let totalXP = xpEarnedToLevel + xpInNewLevel
            resultLines.append("✨ Досвід: Рівень підвищено з \(old.level) до \(new.level)! Набрано \(totalXP) XP (зараз \(new.currentExperience)/\(new.nextLevelExperience) до рівня \(new.level)).")
        } else if new.level > old.level {
            // Leveled up multiple times (rare within short interval, but handle it)
            resultLines.append("✨ Досвід: Рівень підвищено з \(old.level) до \(new.level)! (Декілька рівнів підряд!)")
            resultLines.append("   Досвід: \(new.currentExperience)/\(new.nextLevelExperience) на рівні \(new.level).")
        }
        
        // Guild comparison (if changed)
        if old.guild != new.guild {
            let oldGuild = old.guild ?? "Без гільдії"
            let newGuild = new.guild ?? "Без гільдії"
            resultLines.append("🏰 Гільдія: \(oldGuild) → \(newGuild)")
        }
        
        // Max Health comparison
        if new.maxHealth != old.maxHealth {
            let diff = new.maxHealth - old.maxHealth
            let sign = diff >= 0 ? "+" : ""
            resultLines.append("❤️ Максимальне здоровʼя: \(old.maxHealth) → \(new.maxHealth) (\(sign)\(diff))")
        }
        // Max Energy comparison
        if new.maxEnergy != old.maxEnergy {
            let diff = new.maxEnergy - old.maxEnergy
            let sign = diff >= 0 ? "+" : ""
            resultLines.append("⚡ Максимальна енергія: \(old.maxEnergy) → \(new.maxEnergy) (\(sign)\(diff))")
        }
        
        // Attack, Defense, Hero Power comparisons
        if new.attack != old.attack {
            let diff = new.attack - old.attack
            let sign = diff >= 0 ? "+" : ""
            resultLines.append("⚔️ Атака: \(old.attack) → \(new.attack) (\(sign)\(diff))")
        }
        if new.defense != old.defense {
            let diff = new.defense - old.defense
            let sign = diff >= 0 ? "+" : ""
            resultLines.append("🛡️ Захист: \(old.defense) → \(new.defense) (\(sign)\(diff))")
        }
        if new.heroPower != old.heroPower {
            let diff = new.heroPower - old.heroPower
            let sign = diff >= 0 ? "+" : ""
            resultLines.append("💪 Сила: \(old.heroPower) → \(new.heroPower) (\(sign)\(diff))")
        }
        
        // Gold comparison
        if new.gold != old.gold {
            let diff = new.gold - old.gold
            let sign = diff >= 0 ? "+" : ""
            resultLines.append("💰 Золото: \(old.gold) → \(new.gold) (\(sign)\(diff))")
        }
        
        // Join all lines into one message
        return resultLines.joined(separator: "\n")
    }
}

extension Profile {
    
    /// Helper to parse a time string like "7хв ..." or "1год 30хв ..." into total minutes.
    private static func parseTimeString(_ text: String) -> Int? {
        // text example: "7хв до повного відновлення здоров'я"
        // or "1год 30хв до повного ..." or "1хв до відновлення енергії"
        // We will extract digits and interpret them.
        // Find all digit sequences:
        let components = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                              .filter { !$0.isEmpty }
        guard !components.isEmpty else { return nil }
        // If there's one number:
        if components.count == 1 {
            guard let value = Int(components[0]) else { return nil }
            if text.contains("сек") {
                // If seconds, round up to 1 minute (to avoid 0 minutes remaining).
                return value > 0 ? 1 : 0
            } else if text.contains("хв") && !text.contains("год") {
                // Only minutes
                return value
            } else if text.contains("год") && !text.contains("хв") {
                // Only hours (e.g. "2год")
                return value * 60
            } else {
                return value
            }
        }
        // If two numbers (e.g. hours and minutes):
        if components.count == 2 {
            guard let firstVal = Int(components[0]), let secondVal = Int(components[1]) else { return nil }
            // Assume first is hours, second is minutes if both "год" and "хв" are present
            if text.contains("год") && text.contains("хв") {
                return firstVal * 60 + secondVal
            }
            // If somehow two numbers but not hours+minutes, we default to treating first as minutes and second as seconds
            // (though this case likely won't occur in this game text).
            return firstVal + (secondVal > 0 ? 1 : 0)  // add 1 minute if any seconds remain
        }
        return nil
    }
    
    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.name == rhs.name &&
               lhs.level == rhs.level &&
               lhs.guild == rhs.guild &&
               lhs.maxHealth == rhs.maxHealth &&
               lhs.maxEnergy == rhs.maxEnergy &&
               lhs.attack == rhs.attack &&
               lhs.defense == rhs.defense &&
               lhs.heroPower == rhs.heroPower &&
               lhs.currentExperience == rhs.currentExperience &&
               lhs.nextLevelExperience == rhs.nextLevelExperience &&
               lhs.gold == rhs.gold
    }    
}

extension Profile {
    
    /// Calculate an estimate of days needed to reach the next level based on the history of profiles.
    /// Returns the number of days (as an Int, rounded up) or nil if not enough data.
    func estimateDaysToLevelUp(history: [Profile]) -> Int? {
        guard history.count >= 2 else {
            return nil // Need at least two data points to estimate progress
        }
        // Sort history by timestamp (oldest first)
        let sorted = history.sorted(by: { $0.timestamp < $1.timestamp })
        guard let firstProfile = sorted.first, let latestProfile = sorted.last else {
            return nil
        }
        // Calculate days between the oldest and newest record
        let timeInterval = latestProfile.timestamp.timeIntervalSince(firstProfile.timestamp)
        let daysInterval = timeInterval / (60 * 60 * 24)  // convert seconds to days
        guard daysInterval > 0 else {
            return nil
        }
        // Calculate total experience gained between the two snapshots
        let xpGained = totalXPGained(from: firstProfile, to: latestProfile)
        guard xpGained > 0 else {
            return nil // no XP gained, cannot estimate
        }
        let xpPerDay = Double(xpGained) / daysInterval
        if xpPerDay <= 0 {
            return nil
        }
        // XP remaining to next level from the latest profile
        let remainingXP = latestProfile.nextLevelExperience - latestProfile.currentExperience
        if remainingXP <= 0 {
            return 0  // already leveled up (or at cap)
        }
        // Days needed = remaining XP / (XP per day)
        let rawDaysNeeded = Double(remainingXP) / xpPerDay
        // Round up to the next whole day, since partial days count as a full day of waiting
        let daysNeeded = Int(ceil(rawDaysNeeded))
        return daysNeeded
    }

    /// Helper to calculate total XP gained from an older profile to a newer profile, accounting for level-ups.
    private func totalXPGained(from oldProfile: Profile, to newProfile: Profile) -> Int {
        // If levels are the same
        if newProfile.level == oldProfile.level {
            return newProfile.currentExperience - oldProfile.currentExperience
        }
        // If the new profile is at a higher level than the old profile
        var xpGained = 0
        // XP to finish the oldProfile's level
        xpGained += (oldProfile.nextLevelExperience - oldProfile.currentExperience)
        // If difference in level is more than 1, add full thresholds for intermediate levels.
        if newProfile.level > oldProfile.level + 1 {
            for lvl in (oldProfile.level + 1)..<newProfile.level {
                xpGained += xpThreshold(forLevel: lvl)  // full XP needed for each intermediate level
            }
        }
        // Add XP gained in the current level of newProfile
        xpGained += newProfile.currentExperience
        return xpGained
    }

    /// Estimate the XP threshold for reaching the next level at a given level.
    /// This uses known values for level 10 and 11 and assumes a pattern of increase.
    /// In the actual game, these values might be static or follow a formula.
    private func xpThreshold(forLevel level: Int) -> Int {
        // Known examples: Level 10->11: 20000, Level 11->12: 30000.
        // We'll assume that each level increases the required XP by +10000 for simplicity.
        // (This may need adjustment if the game uses a different progression.)
        switch level {
        case 10: return 20000  // XP needed from level 10 to 11
        case 11: return 30000  // XP needed from level 11 to 12
        default:
            // For higher levels, assume +10000 each level beyond 11
            let level10Threshold = 20000
            let baseIncrement = 10000
            if level <= 10 {
                return level10Threshold  // fallback
            }
            // Example: level=12 -> 40000, 13 -> 50000, etc.
            let extraLevels = level - 11
            return 30000 + extraLevels * baseIncrement
        }
    }
}
