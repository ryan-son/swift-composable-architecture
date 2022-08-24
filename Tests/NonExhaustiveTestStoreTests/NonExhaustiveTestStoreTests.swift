import ComposableArchitecture
import NonExhaustiveTestStore
import XCTest

class NonExhaustiveTestStoreTests: XCTestCase {
  func testNonExhaustiveSend() {

    NonExhaustiveTestStore.init(int: 1)

    let store = NonExhaustiveTestStore<Int, Int, Void, Void, Void>(
      initialState: 0,
      reducer: Reducer<Int, Void, Void> { _, _, _ in .none },
      environment: ()
    )
  }
}
