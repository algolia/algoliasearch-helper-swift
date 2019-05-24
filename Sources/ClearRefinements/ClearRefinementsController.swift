//
//  ClearRefinementsController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 24/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol ClearRefinementsController: class {
  
  var clearRefinements: (() -> Void)? { get set }
  
}

public extension ClearRefinementsController {
  
  func connectFilterState(_ filterState: FilterState) {
    clearRefinements = { [weak filterState] in filterState?.notify(.removeAll) }
  }
  
}
