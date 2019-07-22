//
//  IndexSegmentViewModel+Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 06/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension IndexSegmentViewModel {
  func connectSearcher(searcher: SingleIndexSearcher) {
    if let selected = selected, let index = items[selected] {
      searcher.indexSearchData.index = index
      
    }

    onSelectedComputed.subscribePast(with: self) { (computed) in
      if let selected = computed, let index = self.items[selected] {
        searcher.indexSearchData.index = index
        searcher.search()
      }
    }
  }
}
