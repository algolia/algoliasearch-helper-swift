//
//  SearchController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 22/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol SearchableController: class {
  var onSearch: ((String) -> Void)? { get set }
}
