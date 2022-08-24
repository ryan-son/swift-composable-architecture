import ComposableArchitecture
import XCTest

public class NonExhaustiveTestStore<State, ScopedState, Action, ScopedAction, Environment>:
  TestStore<State, ScopedState, Action, ScopedAction, Environment>
{
  deinit {
    self.skipReceivedActions(strict: false)
    self.skipInFlightEffects(strict: false)
  }
}

extension NonExhaustiveTestStore where ScopedState: Equatable {
  @discardableResult
  public func send(
    _ action: ScopedAction,
    _ updateExpectingResult: ((inout ScopedState) throws -> Void)? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) -> TestStoreTask {
    self.skipReceivedActions(strict: false)
    let task = XCTExpectFailure {
      super.send(action, updateExpectingResult, file: file, line: line)
    }
    do {
      var updated = self.toScopedState(self.state)
      if let updateExpectingResult {
        try updateExpectingResult(&updated)
        XCTAssertEqual(self.toScopedState(self.state), updated, file: file, line: line)
      }
    } catch {
      // TODO: XCTFail
    }
    return task
  }
}

extension NonExhaustiveTestStore where ScopedState: Equatable, Action: Equatable {
  public func receive(
    _ expectedAction: Action,
    _ updateExpectingResult: ((inout ScopedState) throws -> Void)? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    do {
      guard receivedActions.contains(where: { $0.action == expectedAction }) else {
        XCTFail(
        """
        Expected to receive an action \(expectedAction), but didn't get one.
        """,
        file: file, line: line
        )
        return
      }

      while
        let receivedAction = self.receivedActions.first,
        receivedAction.action != expectedAction
      {
        XCTExpectFailure(strict: false) {
          XCTFail("Skipped receiving \(receivedAction.action)", file: file, line: line)
          super.receive(receivedAction.action, file: file, line: line)
        }
      }

      super
        .receive(self.receivedActions.first!.action, updateExpectingResult, file: file, line: line)

      var updated = self.toScopedState(self.state)
      if let updateExpectingResult {
        try updateExpectingResult(&updated)
        XCTAssertEqual(self.toScopedState(self.state), updated, file: file, line: line)
      }
    } catch {
      // TODO: XCTFail
    }
  }
}
