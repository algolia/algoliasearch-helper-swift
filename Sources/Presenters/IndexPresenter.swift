//
//  IndexPresenter.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 12/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias IndexPresenter = (Index) -> String

public extension DefaultPresenter {

  struct Index {

    public static let present: IndexPresenter = { index in
      return index.name
    }

  }
}
