import ComposableArchitecture
import NonExhaustiveTestStore
import XCTest

class NonExhaustiveTestStoreTests: XCTestCase {
  func testNonExhaustiveSend() {




    let store = NonExhaustiveTestStore(
      initialState: CounterState(),
      reducer: counterReducer,
      environment: ()
    )

    // Non-exhaustive assertion. The count is asserted on, but the
    // isEven state is not.
    store.send(.increment) {
      $0.count = 1
    }











    store.send(.decrement) {
      $0.count = 0
    }
    store.send(.increment) {
      $0.isEven = false
    }
    store.send(.decrement) {
      $0.isEven = true
    }
    store.send(.increment) {
      $0.count = 1
      $0.isEven = false
    }
  }

  func testMultipleSendsWithAssertionOnLast() {
    let store = NonExhaustiveTestStore(
      initialState: CounterState(),
      reducer: counterReducer,
      environment: ()
    )

    store.send(.increment)
    store.send(.increment)
    store.send(.increment) {
      $0.count = 3
    }
  }

  func testNonExhaustiveReceive() {
    struct State: Equatable {
      var int = 0
      var string = ""
    }
    enum Action: Equatable {
      case onAppear
      case response1(Int)
      case response2(String)
    }
    let featureReducer = Reducer<State, Action, Void> { state, action, _ in
      switch action {
      case .onAppear:
        state = State()
        return .merge(
          .init(value: .response1(42)),
          .init(value: .response2("Hello"))
        )
      case let .response1(int):
        state.int = int
        return .none
      case let .response2(string):
        state.string = string
        return .none
      }
    }

    let store = NonExhaustiveTestStore(
      initialState: State(),
      reducer: featureReducer,
      environment: ()
    )

    store.send(.onAppear)
    store.receive(.response2("Hello")) {
      $0.string = "Hello"
    }

    store.send(.onAppear)
    store.receive(.response1(42)) {
      $0.int = 42
    }

    store.send(.onAppear)
    store.receive(/Action.response2) {
      $0.int = 42
    }

    XCTExpectFailure {
      store.receive(.response1(1))
    }
  }
}

struct CounterState: Equatable {
  var count = 0
  var isEven = true
}
enum CounterAction {
  case increment
  case decrement
}
let counterReducer = Reducer<CounterState, CounterAction, Void> { state, action, _ in
  switch action {
  case .increment:
    state.count += 1
    state.isEven.toggle()
    return .none
  case .decrement:
    state.count -= 1
    state.isEven.toggle()
    return .none
  }
}
