import XCTest
import Foundation

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

final class AgentStatusBadgeTests: XCTestCase {

    // MARK: - displayLabel

    func testRunningLabel() {
        XCTAssertEqual(AgentStatus.running.displayLabel, "running")
    }

    func testWaitingLabel() {
        XCTAssertEqual(AgentStatus.waiting.displayLabel, "waiting")
    }

    func testDoneLabel() {
        XCTAssertEqual(AgentStatus.done.displayLabel, "done")
    }

    func testErrorLabel() {
        XCTAssertEqual(AgentStatus.error.displayLabel, "error")
    }

    // MARK: - isAnimating

    func testRunningIsAnimating() {
        XCTAssertTrue(AgentStatus.running.isAnimating)
    }

    func testWaitingIsNotAnimating() {
        XCTAssertFalse(AgentStatus.waiting.isAnimating)
    }

    func testDoneIsNotAnimating() {
        XCTAssertFalse(AgentStatus.done.isAnimating)
    }

    func testErrorIsNotAnimating() {
        XCTAssertFalse(AgentStatus.error.isAnimating)
    }

    // MARK: - agentStatus(from:) extraction helper

    func testExtractsAgentStatusFromEntries() {
        let entries: [String: SidebarStatusEntry] = [
            "agent": SidebarStatusEntry(
                key: "agent", value: "running",
                icon: nil, color: nil, timestamp: Date()
            )
        ]
        XCTAssertEqual(AgentStatus.extract(from: entries), .running)
    }

    func testReturnsNilWhenNoAgentKey() {
        let entries: [String: SidebarStatusEntry] = [
            "other": SidebarStatusEntry(
                key: "other", value: "something",
                icon: nil, color: nil, timestamp: Date()
            )
        ]
        XCTAssertNil(AgentStatus.extract(from: entries))
    }

    func testReturnsNilWhenAgentValueUnrecognized() {
        let entries: [String: SidebarStatusEntry] = [
            "agent": SidebarStatusEntry(
                key: "agent", value: "unknown",
                icon: nil, color: nil, timestamp: Date()
            )
        ]
        XCTAssertNil(AgentStatus.extract(from: entries))
    }

    // MARK: - nonAgentEntries(from:) filter helper

    func testFiltersOutAgentKey() {
        let entries: [String: SidebarStatusEntry] = [
            "agent": SidebarStatusEntry(key: "agent", value: "running", icon: nil, color: nil, timestamp: Date()),
            "build": SidebarStatusEntry(key: "build", value: "ok", icon: nil, color: nil, timestamp: Date()),
        ]
        let filtered = AgentStatus.nonAgentEntries(from: entries)
        XCTAssertNil(filtered["agent"])
        XCTAssertNotNil(filtered["build"])
    }

    func testNonAgentEntriesIsUnchangedWhenNoAgentKey() {
        let entries: [String: SidebarStatusEntry] = [
            "build": SidebarStatusEntry(key: "build", value: "ok", icon: nil, color: nil, timestamp: Date()),
        ]
        XCTAssertEqual(AgentStatus.nonAgentEntries(from: entries).count, 1)
    }

    func testNonAgentEntriesIsEmptyWhenOnlyAgentKey() {
        let entries: [String: SidebarStatusEntry] = [
            "agent": SidebarStatusEntry(key: "agent", value: "done", icon: nil, color: nil, timestamp: Date()),
        ]
        XCTAssertTrue(AgentStatus.nonAgentEntries(from: entries).isEmpty)
    }
}
