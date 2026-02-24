import Foundation

/// A snapshot of one workspace's data, used to populate a row in the agent dashboard.
struct AgentDashboardEntry: Identifiable {
    let id: UUID
    let title: String
    let statusEntries: [String: SidebarStatusEntry]
    let gitBranch: SidebarGitBranchState?
    let directory: String?

    // MARK: - Factory

    @MainActor
    static func from(_ workspace: Workspace) -> AgentDashboardEntry {
        AgentDashboardEntry(
            id: workspace.id,
            title: workspace.title,
            statusEntries: workspace.statusEntries,
            gitBranch: workspace.gitBranch,
            directory: workspace.panelDirectories.values.first
        )
    }

    // MARK: - Derived

    var agentStatus: AgentStatus? {
        AgentStatus.extract(from: statusEntries)
    }

    /// Last path component of the working directory.
    var shortDirectory: String? {
        guard let d = directory, !d.isEmpty else { return nil }
        return (d as NSString).lastPathComponent
    }

    /// Elapsed time string since agent status was last set. Nil when no agent status.
    func elapsedTime(now: Date = Date()) -> String? {
        guard let entry = statusEntries["agent"] else { return nil }
        let secs = Int(max(0, now.timeIntervalSince(entry.timestamp)))
        if secs < 60 {
            return "\(secs)s"
        } else if secs < 3600 {
            let m = secs / 60; let s = secs % 60
            return s > 0 ? "\(m)m \(s)s" : "\(m)m"
        } else {
            let h = secs / 3600; let m = (secs % 3600) / 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
    }

    /// Lower value = higher priority in the dashboard list.
    var sortPriority: Int {
        switch agentStatus {
        case .running: return 0
        case .error:   return 1
        case .waiting: return 2
        case .done:    return 3
        case nil:      return 4
        }
    }

    // MARK: - Filter

    enum FilterMode: String, CaseIterable {
        case all
        case activeOnly
        var label: String {
            switch self {
            case .all:        return "All"
            case .activeOnly: return "Active"
            }
        }
    }

    static func filter(_ entries: [AgentDashboardEntry], mode: FilterMode) -> [AgentDashboardEntry] {
        switch mode {
        case .all:        return entries
        case .activeOnly: return entries.filter { $0.agentStatus != nil }
        }
    }
}
