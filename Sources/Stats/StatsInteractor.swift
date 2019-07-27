//
//  StatsInteractor.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 31/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class StatsInteractor: ItemInteractor<SearchStats?> {
  public init() {
    super.init(item: .none)
  }
}

public extension StatsInteractor {
  
  func connectSearcher(_ searcher: SingleIndexSearcher) {
    
    searcher.onResults.subscribePast(with: self) { interactor, searchResults in
        interactor.item = searchResults.stats
    }
    
    searcher.onError.subscribe(with: self) { interactor, _ in
      interactor.item = .none
    }
  }

  func connectController<C: StatsTextController>(_ controller: C, presenter: Presenter<SearchStats?, String?>? = nil) {
    let statsPresenter = presenter ?? DefaultPresenter.Stats.present
    connectController(controller, presenter: statsPresenter)
  }
}