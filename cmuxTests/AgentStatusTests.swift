import XCTest

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

final class AgentStatusTests: XCTestCase {

    // MARK: - Parsing

    func testParseRunning() {
        XCTAssertEqual(AgentStatus.parse("running"), .running)
    }

    func testParseWaiting() {
        XCTAssertEqual(AgentStatus.parse("waiting"), .waiting)
    }

    func testParseDone() {
        XCTAssertEqual(AgentStatus.parse("done"), .done)
    }

    func testParseError() {
        XCTAssertEqual(AgentStatus.parse("error"), .error)
    }

    func testParseInvalidReturnsNil() {
        XCTAssertNil(AgentStatus.parse("invalid"))
    }

    func testParseEmptyReturnsNil() {
        XCTAssertNil(AgentStatus.parse(""))
    }

    func testParseCaseInsensitive() {
        XCTAssertEqual(AgentStatus.parse("RUNNING"), .running)
        XCTAssertEqual(AgentStatus.parse("Done"), .done)
    }

    // MARK: - displayIcon

    func testRunningHasIcon() {
        XCTAssertFalse(AgentStatus.running.displayIcon.isEmpty)
    }

    func testWaitingHasIcon() {
        XCTAssertFalse(AgentStatus.waiting.displayIcon.isEmpty)
    }

    func testDoneHasIcon() {
        XCTAssertFalse(AgentStatus.done.displayIcon.isEmpty)
    }

    func testErrorHasIcon() {
        XCTAssertFalse(AgentStatus.error.displayIcon.isEmpty)
    }

    func testAllIconsAreDistinct() {
        let icons = [
            AgentStatus.running.displayIcon,
            AgentStatus.waiting.displayIcon,
            AgentStatus.done.displayIcon,
            AgentStatus.error.displayIcon,
        ]
        XCTAssertEqual(icons.count, Set(icons).count)
    }

    // MARK: - displayColor

    func testRunningHasColor() {
        XCTAssertFalse(AgentStatus.running.displayColor.isEmpty)
    }

    func testDoneHasColor() {
        XCTAssertFalse(AgentStatus.done.displayColor.isEmpty)
    }

    func testErrorColorIsDifferentFromDone() {
        XCTAssertNotEqual(AgentStatus.error.displayColor, AgentStatus.done.displayColor)
    }

    // MARK: - shouldReplace (dedup)

    func testShouldReplaceWhenCurrentIsNil() {
        XCTAssertTrue(AgentStatus.shouldReplace(current: nil, next: .running))
    }

    func testShouldNotReplaceWhenSameStatus() {
        XCTAssertFalse(AgentStatus.shouldReplace(current: .running, next: .running))
    }

    func testShouldReplaceWhenStatusChanges() {
        XCTAssertTrue(AgentStatus.shouldReplace(current: .running, next: .done))
        XCTAssertTrue(AgentStatus.shouldReplace(current: .done, next: .error))
        XCTAssertTrue(AgentStatus.shouldReplace(current: .waiting, next: .running))
    }

    // MARK: - asSidebarStatusEntry

    func testAsSidebarStatusEntryHasAgentKey() {
        let entry = AgentStatus.running.asSidebarStatusEntry()
        XCTAssertEqual(entry.key, "agent")
    }

    func testAsSidebarStatusEntryHasIcon() {
        let entry = AgentStatus.running.asSidebarStatusEntry()
        XCTAssertNotNil(entry.icon)
    }

    func testAsSidebarStatusEntryHasColor() {
        let entry = AgentStatus.running.asSidebarStatusEntry()
        XCTAssertNotNil(entry.color)
    }

    func testAsSidebarStatusEntryValueMatchesRawValue() {
        XCTAssertEqual(AgentStatus.running.asSidebarStatusEntry().value, "running")
        XCTAssertEqual(AgentStatus.done.asSidebarStatusEntry().value, "done")
        XCTAssertEqual(AgentStatus.error.asSidebarStatusEntry().value, "error")
        XCTAssertEqual(AgentStatus.waiting.asSidebarStatusEntry().value, "waiting")
    }
}
