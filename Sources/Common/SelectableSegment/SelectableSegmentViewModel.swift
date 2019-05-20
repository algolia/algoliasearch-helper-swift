//
//  SelectableMapViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SelectableSegmentViewModel<SegmentKey: Hashable, Segment> {
  
  public var items: [SegmentKey: Segment]
  public var selected: SegmentKey? {
    didSet {
      onSelectedChanged.fire(selected)
    }
  }
  public let onSelectedChanged: Observer<SegmentKey?>
  public let onSelectedComputed: Observer<SegmentKey?>
  
  public init(items: [SegmentKey: Segment]) {
    self.items = items
    self.onSelectedChanged = Observer()
    self.onSelectedComputed = Observer()
  }
  
  public func computeSelected(selected: SegmentKey?) {
    onSelectedComputed.fire(selected)
  }
  
}
