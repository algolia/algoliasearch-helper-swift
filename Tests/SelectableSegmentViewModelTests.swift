//
//  SelectableSegmentViewModelTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class SelectableSegmentViewModelTests: XCTestCase {
  
  typealias VM = SelectableSegmentViewModel<String, String>
  
  func testConstruction() {
    
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])
    
    XCTAssertEqual(viewModel.items, ["k1": "i1", "k2": "i2", "k3": "i3"])
    XCTAssertNil(viewModel.selected)
    
  }
  
  func testSelection() {
    
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])

    let selectionExp = expectation(description: "selection expectation")
    
    viewModel.onSelectedChanged.subscribe(with: self) { selectedKey in
      XCTAssertEqual(selectedKey, "k3")
      selectionExp.fulfill()
    }
    
    viewModel.selected = "k3"
    
    XCTAssertEqual(viewModel.selected, "k3")
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testSelectionComputed() {
    
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])

    let selectionComputedExp = expectation(description: "selection computed expectation")
    
    viewModel.onSelectedComputed.subscribe(with: self) { computedSelection in
      XCTAssertEqual(computedSelection, "k3")
      selectionComputedExp.fulfill()
    }
    
    viewModel.computeSelected(selected: "k3")
    
    waitForExpectations(timeout: 2, handler: .none)

  }
  
  func nilSelectedComputedTest() {
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])
    
    let selectionComputedExp = expectation(description: "selection computed expectation")
    
    viewModel.onSelectedComputed.subscribe(with: self) { computedSelection in
      XCTAssertNil(computedSelection)
      selectionComputedExp.fulfill()
    }
    
    viewModel.computeSelected(selected: nil)
    
    waitForExpectations(timeout: 2, handler: .none)
  }
  
}
