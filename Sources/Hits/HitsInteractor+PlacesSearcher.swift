//
//  HitsInteractor+PlacesSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 29/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension HitsInteractor where Record == Place {
  
  public func connectPlacesSearcher(_ searcher: PlacesSearcher) {
    
    searcher.onResults.subscribePast(with: self) { interactor, searchResults in
      try? interactor.update(searchResults)
    }

    searcher.onError.subscribe(with: self) { interactor, arg in
      //TODO: when pagination added, notify pending query in infinite scrolling controller
    }
    
    searcher.onQueryChanged.subscribe(with: self) { (interactor, query) in
      interactor.notifyQueryChanged()
    }
    
  }
  
}
