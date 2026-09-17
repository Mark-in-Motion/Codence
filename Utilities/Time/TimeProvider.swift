import Foundation

/// Time abstraction so sync and retry logic can be tested deterministically.
protocol TimeProvider {
    var now: Date { get }
}
