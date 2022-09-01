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
    strict: Bool = false,
    _ updateExpectingResult: ((inout ScopedState) throws -> Void)? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) -> TestStoreTask {
    guard !strict
    else {
      return super.send(action, updateExpectingResult, file: file, line: line)
    }

    self.skipReceivedActions(strict: false)
    let task = XCTExpectFailure(strict: false) {
      super.send(action, updateExpectingResult, file: file, line: line, prefix: "The following assertions were skipped.")
    }
    do {
      var updated = self.toScopedState(self.state)
      if let updateExpectingResult = updateExpectingResult {
        try updateExpectingResult(&updated)
        XCTAssertEqual(self.toScopedState(self.state), updated, file: file, line: line)
      }
    } catch {
      XCTFail("Threw error: \(error)", file: file, line: line)
    }
    return task
  }
}

extension NonExhaustiveTestStore where ScopedState: Equatable, Action: Equatable {
  public func receive<Value>(
    _ expectedAction: CasePath<Action, Value>,
    _ updateExpectingResult: ((inout ScopedState) throws -> Void)? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    do {
      guard receivedActions.contains(where: { expectedAction.extract(from: $0.action) != nil })
      else {
        XCTFail(
          """
          Expected to receive an action \(expectedAction), but didn't get one.
          """,
          file: file, line: line
        )
        return
      }

      while let receivedAction = self.receivedActions.first,
        expectedAction.extract(from: receivedAction.action) != nil
      {
        XCTExpectFailure(strict: false) {
          XCTFail("Skipped receiving \(receivedAction.action)", file: file, line: line)
          super.receive(receivedAction.action, file: file, line: line)
        }
      }

      super
        .receive(self.receivedActions.first!.action, updateExpectingResult, file: file, line: line)

      var updated = self.toScopedState(self.state)
      if let updateExpectingResult = updateExpectingResult {
        try updateExpectingResult(&updated)
        XCTAssertEqual(self.toScopedState(self.state), updated, file: file, line: line)
      }
    } catch {
      XCTFail("Threw error: \(error)", file: file, line: line)
    }
  }

  public func receive(
    _ expectedAction: Action,
    strict: Bool = false,
    _ updateExpectingResult: ((inout ScopedState) throws -> Void)? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    guard !strict
    else {
      return super.receive(expectedAction, updateExpectingResult, file: file, line: line)
    }

    do {
      guard receivedActions.contains(where: { $0.action == expectedAction }) else {
        XCTFail(
          """
          Expected to receive an action \(expectedAction), but didn't get one.
          """,
          file: file,
          line: line
        )
        return
      }

      while let receivedAction = self.receivedActions.first,
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
      if let updateExpectingResult = updateExpectingResult {
        try updateExpectingResult(&updated)
        XCTAssertEqual(self.toScopedState(self.state), updated, file: file, line: line)
      }
    } catch {
      XCTFail("Threw error: \(error)", file: file, line: line)
    }
  }
}
