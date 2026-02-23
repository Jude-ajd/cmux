import SwiftUI

// MARK: - Main overlay

struct AgentDashboardOverlay: View {
    @EnvironmentObject var tabManager: TabManager
    @Binding var isPresented: Bool
    @State private var filterMode: AgentDashboardEntry.FilterMode = .all
    @State private var now = Date()

    // Refresh elapsed time every second
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                header
                Divider()
                content
            }
            .frame(width: 560)
            .frame(maxHeight: 480)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 8)
        }
        .onExitCommand { dismiss() }
        .onReceive(timer) { now = $0 }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Agent Dashboard")
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Filter", selection: $filterMode) {
                ForEach(AgentDashboardEntry.FilterMode.allCases, id: \.self) {
                    Text($0.label).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 130)
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Content

    private var content: some View {
        let entries = filteredEntries
        return Group {
            if entries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(entries) { entry in
                            AgentDashboardRow(
                                entry: entry,
                                isSelected: tabManager.selectedTabId == entry.id,
                                now: now
                            ) {
                                if let ws = tabManager.tabs.first(where: { $0.id == entry.id }) {
                                    tabManager.selectTab(ws)
                                }
                                dismiss()
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text(filterMode == .activeOnly ? "No active agents" : "No workspaces")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    // MARK: - Derived

    private var filteredEntries: [AgentDashboardEntry] {
        let all = tabManager.tabs.map { AgentDashboardEntry.from($0) }
        let filtered = AgentDashboardEntry.filter(all, mode: filterMode)
        return filtered.sorted {
            if $0.sortPriority != $1.sortPriority { return $0.sortPriority < $1.sortPriority }
            let t0 = $0.statusEntries["agent"]?.timestamp ?? .distantPast
            let t1 = $1.statusEntries["agent"]?.timestamp ?? .distantPast
            return t0 > t1
        }
    }

    private var subtitle: String {
        let total = tabManager.tabs.count
        let active = tabManager.tabs.filter {
            AgentStatus.extract(from: $0.statusEntries) != nil
        }.count
        if active == 0 { return "\(total) workspaces" }
        return "\(total) workspaces · \(active) active"
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.15)) { isPresented = false }
    }
}

// MARK: - Row

private struct AgentDashboardRow: View {
    let entry: AgentDashboardEntry
    let isSelected: Bool
    let now: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Status badge or placeholder dot
                if let status = entry.agentStatus {
                    AgentStatusBadge(status: status, isActive: false)
                        .frame(width: 80, alignment: .leading)
                } else {
                    Text("—")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .frame(width: 80, alignment: .leading)
                }

                // Title
                Text(entry.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Branch
                if let branch = entry.gitBranch?.branch {
                    Label(branch, systemImage: "arrow.triangle.branch")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: 120, alignment: .trailing)
                }

                // Elapsed time
                if let t = entry.elapsedTime(now: now) {
                    Text(t)
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .frame(width: 52, alignment: .trailing)
                } else {
                    Text("")
                        .frame(width: 52)
                }

                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
