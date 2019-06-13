//
//  IndexSegmentViewModel+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 06/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias IndexPresenter = (Index) -> String

public struct DefaultIndexPresenter {

  public static let present: IndexPresenter = { index in
    return index.name
  }

}

public extension IndexSegmentViewModel {
  func connectController<C: SelectableSegmentController>(_ controller: C, presenter: IndexPresenter? = .none) where C.SegmentKey == SegmentKey {

    let presenter = presenter ?? DefaultIndexPresenter.present

    controller.setItems(items: items.mapValues { presenter($0) })
    controller.onClick = computeSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller, callback: controller.setSelected)
    onItemsChanged.subscribePast(with: controller) { (newItems) in
      controller.setItems(items: newItems.mapValues { presenter($0) })
    }

  }
}