@testable import HeroKit
import Testing

extension ViewModelTest {
    @Suite("HeaderView Style")
    struct HeaderViewStyleTests {

        func didSetup() {
            let sut = HeroHeader.ViewModel(configuration: .init(height: 100))
            sut.didSetup()
        }
    }
}
