//
//  NearbySearchResponse.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 06/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import ObjectMapper

class NearbySearchResponse: Decodable, Mappable {

    var nextPageToken: String?
    var results: [NearbySearchItem]?
    var status: String?

    required init?(map: Map) { }
    
    func mapping(map: Map) {
        nextPageToken <- map[CodingKeys.nextPageToken.rawValue]
        results <- map[CodingKeys.results.rawValue]
        status <- map[CodingKeys.status.rawValue]
    }
    
    enum CodingKeys: String, CodingKey {
        case nextPageToken = "next_page_token"
        case results, status
    }
    
    init(nextPageToken: String?, results: [NearbySearchItem]?, status: String?) {
        self.nextPageToken = nextPageToken
        self.results = results
        self.status = status
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nextPageToken = try container.decodeIfPresent(String.self, forKey: .nextPageToken)
        let results = try container.decodeIfPresent([NearbySearchItem].self, forKey: .results)
        let status = try container.decodeIfPresent(String.self, forKey: .status)
        self.init(nextPageToken: nextPageToken, results: results, status: status)
    }
}

class NearbySearchItem: Decodable, Mappable {
    var geometry: Geometry?
    var icon: String?
    var id, name: String?
    var placeID, reference, scope: String?
    var types: [String]?
    var vicinity: String?
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        geometry <- map[CodingKeys.geometry.rawValue]
        icon <- map[CodingKeys.icon.rawValue]
        id <- map[CodingKeys.id.rawValue]
        name <- map[CodingKeys.name.rawValue]
        placeID <- map[CodingKeys.placeID.rawValue]
        reference <- map[CodingKeys.reference.rawValue]
        scope <- map[CodingKeys.scope.rawValue]
        types <- map[CodingKeys.types.rawValue]
        vicinity <- map[CodingKeys.vicinity.rawValue]
    }
    
    enum CodingKeys: String, CodingKey {
        case geometry, icon, id, name, photos
        case placeID = "place_id"
        case reference, scope, types, vicinity
    }
    
    init(geometry: Geometry?, icon: String?, id: String?, name: String?, placeID: String?, reference: String?, scope: String?, types: [String]?, vicinity: String?) {
        self.geometry = geometry
        self.icon = icon
        self.id = id
        self.name = name
        self.placeID = placeID
        self.reference = reference
        self.scope = scope
        self.types = types
        self.vicinity = vicinity
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let geometry = try container.decodeIfPresent(Geometry.self, forKey: .geometry)
        let icon = try container.decodeIfPresent(String.self, forKey: .geometry)
        let id = try container.decodeIfPresent(String.self, forKey: .geometry)
        let name = try container.decodeIfPresent(String.self, forKey: .geometry)
        let placeID = try container.decodeIfPresent(String.self, forKey: .geometry)
        let reference = try container.decodeIfPresent(String.self, forKey: .geometry)
        let scope = try container.decodeIfPresent(String.self, forKey: .geometry)
        let types = try container.decodeIfPresent([String].self, forKey: .geometry)
        let vicinity = try container.decodeIfPresent(String.self, forKey: .geometry)

        self.init(
            geometry: geometry,
            icon: icon,
            id: id,
            name: name,
            placeID: placeID,
            reference: reference,
            scope: scope,
            types: types,
            vicinity: vicinity)
    }
}

class Geometry: Codable, ImmutableMappable {
    let location: GoogleLocation

    required init(map: Map) throws {
        location = try map.value("location")
    }
    
    init(location: GoogleLocation) {
        self.location = location
    }
}

class GoogleLocation: Codable, ImmutableMappable {
    required init(map: Map) throws {
        lat = try map.value("lat")
        lng = try map.value("lng")
    }
    
    let lat, lng: Double
    
    init(lat: Double, lng: Double) {
        self.lat = lat
        self.lng = lng
    }
}
