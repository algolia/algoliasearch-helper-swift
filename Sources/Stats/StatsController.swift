//
//  StatsController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol StatsController: ItemController where Item == SearchResults<Record> {
  associatedtype Record: Codable
  
}
