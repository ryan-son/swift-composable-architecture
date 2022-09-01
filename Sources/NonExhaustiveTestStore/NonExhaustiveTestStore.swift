import ComposableArchitecture
import CustomDump
import Foundation
import XCTestDynamicOverlay

public class NonExhaustiveTestStore<State, ScopedState, Action, ScopedAction, Environment>:
  TestStore<State, ScopedState, Action, ScopedAction, Environment>
{
  deinit {
    self.skipReceivedActions(strict: false, prefix: "✅ Skipped assertions: …")
    self.skipInFlightEffects(strict: false, prefix: "✅ Skipped assertions: …")
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
    let task = _XCTExpectFailure(strict: false) {
      super.send(
        action,
        prefix: "✅ Skipped assertions: …",
        updateExpectingResult,
        file: file,
        line: line
      )
    }
    do {
      var expected = self.toScopedState(self.state)
      if let updateExpectingResult = updateExpectingResult {
        try updateExpectingResult(&expected)
        let actual = self.toScopedState(self.state)
        if actual != expected {
          let difference =
            diff(expected, actual, format: .proportional)
            .map { "\($0.indent(by: 4))\n\n(Expected: −, Actual: +)" }
            ?? """
            Expected:
            \(String(describing: expected).indent(by: 2))

            Actual:
            \(String(describing: actual).indent(by: 2))
            """

          XCTFail(
            """
            A state change does not match expectation: …

            \(difference)
            """,
            file: file,
            line: line
          )
        }
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
        expectedAction.extract(from: receivedAction.action) == nil
      {
        _XCTExpectFailure(strict: false) {
          XCTFail(
            """
            ✅ Skipped assertions: …

            Skipped receiving \(receivedAction.action)
            """,
            file: file,
            line: line
          )
          super.receive(
            receivedAction.action,
            prefix: "✅ Skipped assertions: …",
            file: file,
            line: line
          )
        }
      }

      _XCTExpectFailure(strict: false) {
        super.receive(
          self.receivedActions.first!.action,
          prefix: "✅ Skipped assertions: …",
          updateExpectingResult,
          file: file,
          line: line
        )
      }

      var expected = self.toScopedState(self.state)
      if let updateExpectingResult = updateExpectingResult {
        try updateExpectingResult(&expected)
        let actual = self.toScopedState(self.state)
        if actual != expected {
          let difference =
            diff(expected, actual, format: .proportional)
            .map { "\($0.indent(by: 4))\n\n(Expected: −, Actual: +)" }
            ?? """
            Expected:
            \(String(describing: expected).indent(by: 2))

            Actual:
            \(String(describing: actual).indent(by: 2))
            """

          XCTFail(
            """
            A state change does not match expectation: …

            \(difference)
            """,
            file: file,
            line: line
          )
        }
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
        _XCTExpectFailure(strict: false) {
          XCTFail(
            """
            ✅ Skipped assertions: …

            Skipped receiving \(receivedAction.action)
            """,
            file: file,
            line: line
          )
          super.receive(
            receivedAction.action,
            prefix: "✅ Skipped assertions: …",
            file: file,
            line: line
          )
        }
      }

      _XCTExpectFailure(strict: false) {
        super.receive(
          self.receivedActions.first!.action,
          prefix: "✅ Skipped assertions: …",
          updateExpectingResult,
          file: file,
          line: line
        )
      }

      var expected = self.toScopedState(self.state)
      if let updateExpectingResult = updateExpectingResult {
        try updateExpectingResult(&expected)
        let actual = self.toScopedState(self.state)
        if actual != expected {
          let difference =
            diff(expected, actual, format: .proportional)
            .map { "\($0.indent(by: 4))\n\n(Expected: −, Actual: +)" }
            ?? """
            Expected:
            \(String(describing: expected).indent(by: 2))

            Actual:
            \(String(describing: actual).indent(by: 2))
            """

          XCTFail(
            """
            A state change does not match expectation: …

            \(difference)
            """,
            file: file,
            line: line
          )
        }
      }
    } catch {
      XCTFail("Threw error: \(error)", file: file, line: line)
    }
  }
}

struct XCTExpectFailureUnavailable: Error {}

// TODO: Move to XCTest Dynamic Overlay
func _XCTExpectFailure<R>(
  _ failureReason: String? = nil,
  strict: Bool = true,
  failingBlock: () -> R
) -> R {
  guard
    let XCTExpectedFailureOptions = NSClassFromString("XCTExpectedFailureOptions")
      as Any as? NSObjectProtocol,
    let options = strict
      ? XCTExpectedFailureOptions
        .perform(NSSelectorFromString("alloc"))?.takeUnretainedValue()
        .perform(NSSelectorFromString("init"))?.takeUnretainedValue()
      : XCTExpectedFailureOptions
        .perform(NSSelectorFromString("nonStrictOptions"))?.takeUnretainedValue()
  else {
    return failingBlock()
  }

  let XCTExpectFailureWithOptionsInBlock = unsafeBitCast(
    dlsym(dlopen(nil, RTLD_LAZY), "XCTExpectFailureWithOptionsInBlock"),
    to: (@convention(c) (String?, AnyObject, () -> Void) -> Void).self
  )

  var result: R!
  XCTExpectFailureWithOptionsInBlock(failureReason, options) {
    result = failingBlock()
  }
  return result
}

extension String {
  func indent(by indent: Int) -> String {
    let indentation = String(repeating: " ", count: indent)
    return indentation + self.replacingOccurrences(of: "\n", with: "\n\(indentation)")
  }
}
