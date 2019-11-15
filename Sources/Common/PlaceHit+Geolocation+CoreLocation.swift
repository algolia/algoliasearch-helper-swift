//
//  PlaceHit+Geolocation+CoreLocation.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

import CoreLocation

extension PlaceHit.Geolocation {
  
  init(_ coordinate: CLLocationCoordinate2D) {
    self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }
  
}

extension CLLocationCoordinate2D {
  
  init(_ geolocation: PlaceHit.Geolocation) {
    self.init(latitude: geolocation.latitude, longitude: geolocation.longitude)
  }
  
}
