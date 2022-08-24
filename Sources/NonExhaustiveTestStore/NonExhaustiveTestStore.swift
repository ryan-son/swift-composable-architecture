import ComposableArchitecture
import XCTest

public class NonExhaustiveTestStore<State, ScopedState, Action, ScopedAction, Environment>
: TestStore<State, ScopedState, Action, ScopedAction, Environment> {

  deinit {
    self.skipReceivedActions(strict: false)
    self.skipInFlightEffects()
  }
}

extension NonExhaustiveTestStore where State == ScopedState, Action == ScopedAction {
  public convenience init(
    initialState: State,
    reducer: Reducer<State, Action, Environment>,
    environment: Environment,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    self.init(
      initialState: initialState,
      reducer: reducer,
      environment: environment,
      file: file,
      line: line
    )
  }

}

extension NonExhaustiveTestStore where ScopedState: Equatable {
  public func send(
    _ action: ScopedAction,
    _ updateExpectingResult: ((inout ScopedState) throws -> Void)? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    do {
      self.skipReceivedActions(strict: false)

      _ = XCTExpectFailure {
        super.send(action, updateExpectingResult, file: file, line: line)
      }

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
          super.receive(receivedAction.action, file: file, line: line)
        }
      }

      XCTExpectFailure(strict: false) {
        super.receive(self.receivedActions.first!.action, file: file, line: line)
      }

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
