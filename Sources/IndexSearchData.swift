//
//  IndexSearchData.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 27/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/// Structure containing all necessary components to perform a search

public struct IndexSearchData {
  
  /// Index in which search will be performed
  public var index: Index
  
  /// Query describing a search request
  public let query: Query
  
  public init(index: Index,
              query: Query = .init()) {
    self.index = index
    self.query = query
  }
  
}

extension IndexQuery {
  
  convenience init(indexSearchData: IndexSearchData) {
    self.init(index: indexSearchData.index, query: indexSearchData.query)
  }
  
}

extension Array where Element == IndexSearchData {
  
  init(indices: [InstantSearchClient.Index], query: Query = .init()) {
    self = indices.map { IndexSearchData(index: $0, query: query) }
  }
  
}
