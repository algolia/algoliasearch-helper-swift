//
//  FilterComparisonComputeBounds.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol InitaliazableWithFloat {

  init(_ float: Float)
  func toFloat() -> Float
}

extension Int: InitaliazableWithFloat {
  public func toFloat() -> Float {
    return Float(self)
  }
}

extension Double: InitaliazableWithFloat {
  public func toFloat() -> Float {
    return Float(self)
  }
}

extension Float: InitaliazableWithFloat {
  public func toFloat() -> Float {
    return Float(self)
  }
}

public extension NumberViewModel {
  func computeBoundsFromFacetStats<T>(attribute: Attribute, facetStats: [Attribute: SearchResults<T>.FacetStats]?) {
    guard let facetStats = facetStats, let facetStatsOfAttribute = facetStats[attribute] else {
      applyBounds(bounds: nil)
      return
    }

    applyBounds(bounds: Number(facetStatsOfAttribute.min)...Number(facetStatsOfAttribute.max))
  }
}
