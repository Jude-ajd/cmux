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

    // MARK: - Dedup

    /// Returns true only when the status actually changes, preventing no-op UI updates.
    static func shouldReplace(current: AgentStatus?, next: AgentStatus) -> Bool {
        current != next
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
