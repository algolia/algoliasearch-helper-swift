//
//  Logging.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 11/02/2020.
//  Copyright © 2020 Algolia. All rights reserved.
//

import Foundation
import Logging

typealias SwiftLog = Logging.Logger

struct Logger {
  
  static var loggingService: Loggable = SwiftLog(label: "com.algolia.InstantSearch")
  
  private init() {}
  
  static func trace(_ message: String) {
    loggingService.log(level: .trace, message: message)
  }
  
  static func debug(_ message: String) {
    loggingService.log(level: .debug, message: message)
  }
  
  static func info(_ message: String) {
    loggingService.log(level: .info, message: message)
  }
  
  static func notice(_ message: String) {
    loggingService.log(level: .notice, message: message)
  }
  
  static func warning(_ message: String) {
    loggingService.log(level: .warning, message: message)
  }
  
  static func error(_ message: String) {
    loggingService.log(level: .error, message: message)
  }
  
  static func critical(_ message: String) {
    loggingService.log(level: .critical, message: message)
  }
  
}

enum LogLevel {
  case trace, debug, info, notice, warning, error, critical
}

extension Logger {
    
  static func error(_ error: Error) {
    if let decodingError = error as? DecodingError {
      self.error(DecodingErrorPrettyPrinter(decodingError: decodingError).description)
    } else {
      self.error("\(error)")
    }
  }
  
  static func resultsReceived(forQuery query: String?, results: SearchResults) {
    let query = query ?? ""
    let message = """
    Results received for query: \(query)
    Hits count: \(results.stats.totalHitsCount)
    Processing time: \(results.stats.processingTimeMS)
    """
    self.info(message)
  }
  
}

extension LogLevel {
  
  var swiftLogLevel: SwiftLog.Level {
    switch self {
    case .trace: return .trace
    case .debug: return .debug
    case .info: return .info
    case .notice: return .notice
    case .warning: return .warning
    case .error: return .error
    case .critical: return .critical
    }
  }
  
}

protocol Loggable {
  
  func log(level: LogLevel, message: String)
  
}

extension SwiftLog: Loggable {
  
  func log(level: LogLevel, message: String) {
    self.log(level: level.swiftLogLevel, SwiftLog.Message(stringLiteral: message), metadata: .none)
  }
  
}
