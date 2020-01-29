//
//  GooglePlaceService.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 06/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import RxAlamofire
import CoreLocation
import ObjectMapper

class GooglePlaceService {
    
    private let key = "AIzaSyCjezlcK69lITrnMKKCE28LJZJFM8W6vzs"
    private let baseUrl = "https://maps.googleapis.com/maps/api/place/"
    
    private static var shared: GooglePlaceService = {
        let service = GooglePlaceService()
        return service
    }()
    
    static func instance() -> GooglePlaceService {
        return GooglePlaceService.shared
    }
    
    private init() { }
    
    func nearbySearch(location: CLLocation, radiusInMeters: Int) -> Single<NearbySearchResponse?> {
        let manager = SessionManager.default
        let url = baseUrl + "nearbysearch/json"
        let params : [String : Any] = [
            "location" : "\(location.coordinate.latitude),\(location.coordinate.longitude)",
            "radius" : radiusInMeters,
            "key" : key]
        
        return manager.rx
            .json(.get, url, parameters: params, encoding: URLEncoding.default, headers: nil)
            .asSingle()
            .map { (result : Any) -> NearbySearchResponse? in
                return Mapper<NearbySearchResponse>().map(JSONObject: result)
            }
    }

}
