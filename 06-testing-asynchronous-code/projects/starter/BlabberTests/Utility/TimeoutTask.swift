//
//  TimeoutTask.swift
//  BlabberTests
//
//  Created by 김인환 on 2/9/25.
//

import Foundation

@MainActor
class TimeoutTask<Success> {
  let seconds: Int
  let operation: @Sendable () async throws -> Success
  
  private var continuation: CheckedContinuation<Success, Error>?
  
  var value: Success {
    get async throws {
      try await withCheckedThrowingContinuation { continuation in
        self.continuation = continuation
        Task {
          print(#function, "Thread: \(Thread.current)")
          try await Task.sleep(for: .seconds(seconds))
          self.continuation?.resume(throwing: TimeoutError())
          self.continuation = nil
        }
        Task {
          print(#function, "Thread: \(Thread.current)")
          let result = try await operation()
          self.continuation?.resume(returning: result)
          self.continuation = nil
        }
      }
    }
  }
  
  init(
    seconds: Int,
    operation: @escaping @Sendable () async throws -> Success
  ) {
    self.seconds = seconds
    self.operation = operation
  }
  
  func cancel() {
    continuation?.resume(throwing: CancellationError())
    continuation = nil
  }
}

extension TimeoutTask {
  struct TimeoutError: LocalizedError {
    var errorDescription: String? {
      return "The operation timed out."
    }
  }
}
