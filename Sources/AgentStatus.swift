import Foundation

/// Typed agent status for AI coding agent sessions (e.g. Claude Code).
/// Displayed as a dedicated indicator in the sidebar tab.
enum AgentStatus: String, Equatable {
    case running
    case waiting
    case done
    case error

    // MARK: - Parsing

    /// Parse a raw string into an AgentStatus, case-insensitively.
    static func parse(_ raw: String) -> AgentStatus? {
        AgentStatus(rawValue: raw.lowercased())
    }

    // MARK: - Display

    /// SF Symbol name for this status.
    var displayIcon: String {
        switch self {
        case .running: return "arrow.trianglehead.2.clockwise"
        case .waiting: return "pause.circle"
        case .done:    return "checkmark.circle"
        case .error:   return "exclamationmark.triangle"
        }
    }

    /// Hex color string for this status.
    var displayColor: String {
        switch self {
        case .running: return "#3b82f6"  // blue
        case .waiting: return "#f59e0b"  // amber
        case .done:    return "#22c55e"  // green
        case .error:   return "#ef4444"  // red
        }
    }

    /// Human-readable label shown in the sidebar badge.
    var displayLabel: String { rawValue }

    /// Whether the badge should show a pulsing animation (only while running).
    var isAnimating: Bool { self == .running }

    // MARK: - Dedup

    /// Returns true only when the status actually changes, preventing no-op UI updates.
    static func shouldReplace(current: AgentStatus?, next: AgentStatus) -> Bool {
        current != next
    }

    // MARK: - SidebarStatusEntry helpers

    /// Extracts AgentStatus from a statusEntries dictionary, or nil if absent/unrecognized.
    static func extract(from entries: [String: SidebarStatusEntry]) -> AgentStatus? {
        guard let entry = entries["agent"] else { return nil }
        return AgentStatus.parse(entry.value)
    }

    /// Returns all entries except the "agent" key (so the generic pill row skips it).
    static func nonAgentEntries(from entries: [String: SidebarStatusEntry]) -> [String: SidebarStatusEntry] {
        entries.filter { $0.key != "agent" }
    }

    // MARK: - SidebarStatusEntry conversion

    /// Converts this status into a SidebarStatusEntry keyed as "agent".
    func asSidebarStatusEntry() -> SidebarStatusEntry {
        SidebarStatusEntry(
            key: "agent",
            value: rawValue,
            icon: displayIcon,
            color: displayColor,
            timestamp: Date()
        )
    }
}
