import ComposableArchitecture
import NonExhaustiveTestStore
import XCTest

class NonExhaustiveTestStoreTests: XCTestCase {
  func testNonExhaustiveSend() {
    let store = NonExhaustiveTestStore(
      initialState: 0,
      reducer: Reducer<Int, Void, Void> { _, _, _ in .none },
      environment: ()
    )
  }

  func testSend() {
    let mainQueue = DispatchQueue.test
    struct State: Equatable {
      var count = 0
      var ignored = ""
    }
    enum Action: Equatable { case incr, decr, response1, response2 }
    let store = NonExhaustiveTestStore(
      initialState: State(),
      reducer: Reducer<State, Action, Void> { state, action, _ in
        switch action {
        case .incr:
          state.count += 1
          state.ignored += "!"
          return .concatenate(
            Effect(value: .response1)
            .receive(on: mainQueue)
            .eraseToEffect(),
            Effect(value: .response2)
              .receive(on: mainQueue)
              .eraseToEffect()
            )
        case .decr:
          state.count -= 1
          state.ignored += "?"
          return .none
        case .response1:
          state.count += 2
          return .none
        case .response2:
          state.count += 4
          return .none
        }
      },
      environment: ()
    )

    store.send(.incr) {
      $0.count = 1
    }
    mainQueue.advance()
    mainQueue.advance()

    store.receive(.response2) {
      $0.count = 7
    }
  }
}
