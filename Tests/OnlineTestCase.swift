//
//  OnlineTestCase.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import InstantSearchClient
import XCTest

/// Abstract base class for online test cases.
///
class OnlineTestCase: XCTestCase {
  var expectationTimeout: TimeInterval = 100
  
  var client: Client!
  var index: Index!
  
  override func setUp() {
    super.setUp()
    
    // Init client.
    let appID = "1M1U6ZWKZP" //Bundle(for: type(of: self)).object(forInfoDictionaryKey: ) as? String ?? ""
    let apiKey = "c762c14ebbd970c7f5c7ec6654b26472" //Bundle(for: type(of: self)).object(forInfoDictionaryKey: ) as? String ?? ""
    client = InstantSearchClient.Client(appID: appID, apiKey: apiKey)
    
    // Init index.
    // NOTE: We use a different index name for each test function.
    let className = String(reflecting: type(of: self)).components(separatedBy: ".").last!
    let functionName = invocation!.selector.description
    let indexName = "\(className).\(functionName)"
    index = client.index(withName: safeIndexName(indexName))
    
    // Delete the index.
    // Although it's not shared with other test functions, it could remain from a previous execution.
    let expectation = self.expectation(description: "Delete index")
    client.deleteIndex(withName: index.name) { (content, error) -> Void in
      if let error = error {
        XCTFail(error.localizedDescription)
        return
      }
      guard let content = content, let taskID = content["taskID"] as? Int else {
        XCTFail("Task ID not returned for deleteIndex")
        return
      }
      self.index.waitTask(withID: taskID) { _, error in
        XCTAssertNil(error)
        expectation.fulfill()
      }
    }
    waitForExpectations(timeout: expectationTimeout, handler: nil)
  }
  
  override func tearDown() {
    super.tearDown()
    
    let expectation = self.expectation(description: "Delete index")
    client.deleteIndex(withName: index.name) { (_, error) -> Void in
      XCTAssertNil(error)
      expectation.fulfill()
    }
    waitForExpectations(timeout: expectationTimeout, handler: nil)
  }
}
