//
//  Constants.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import CoreLocation

// Offset btw content at bottom, inside card view to main view bottom
let contentBottomOffset: CGFloat = 42.0
let settingsSocialRowSpace: CGFloat = 20.0

let awsBucket = "orbis-userfiles-mobilehub-538040402"
let orbisDomain = "orbis.to"
let orbisWebSite = "https://orbis.to"
let tosPage = URL(string: "\(orbisWebSite)/tos")!
let policyPage = URL(string: "\(orbisWebSite)/privacy")!
let googlePlaceUserId = "CCZwVC59kqN29RiS9pNEzOhGOtx1"

let checkInLifeTime: Int = 60 * 24

let groupDescriptionMinLenght = 15
let paginationCount = 20

let buenosAiresCoordinates = Coordinates(latitude: -34.603683, longitude: -58.381557)

let estrelaCoordinates = Coordinates(latitude: -29.48, longitude: -51.96)
let lajeadoCoordinates = Coordinates(latitude: -29.465247983979687, longitude: -51.970731653273106)
let rioDeJaneiroCoordinates = Coordinates(latitude: -23.0078425, longitude: -43.3154218)
let rioDeJaneiroCoordinates2 = Coordinates(latitude: -22.9113, longitude: -43.179)
let barraDaTijuca = Coordinates(latitude: -22.992601, longitude: -43.356726)
let teutoniaCoordinates = Coordinates(latitude: -29.4784, longitude: -51.8236)
let currentTestingCoordinates = Coordinates(latitude: -23.0078425, longitude: -43.3154218)


let feedsByDistanceInMeters = 25000.0
let myFeedsDistanceInMeters = 50000.0 // #278
let placesListMaxRadiusInKm = 20.0

let geoFireMaxRadiusInKm = 1.1//4000.0
let maxNearbySearchRadiusInMeters = 5000
let maxCheckInDistanceInMeters: Double = 1000
let mapInitialDistance: CLLocationDistance = 16000
let mapAnimDistance: CLLocationDistance = 2000
let mapInitialZoom = 15
let mapZoomDiffToAndroid = 3.0

// Temporary workaround to make size of circles on iOS similar to Android
let iosSizeFactor: Double = 8.0

// This means after x-1 items an ad will be displayed
let adsFrequency = 8

let googlePlaceTypes: [String : PlaceType] = [
    "accounting" : PlaceType.twoBuildings,
    "airport" : PlaceType.building,
    "amusement_park" : PlaceType.park,
    "aquarium" : PlaceType.park,
    "art_gallery" : PlaceType.castle,
    "atm" : PlaceType.building,
    "bakery" : PlaceType.restaurant,
    "bank" : PlaceType.house,
    "bar" : PlaceType.bar,
    "beauty_salon" : PlaceType.house2,
    "bicycle_store" : PlaceType.shopping,
    "book_store" : PlaceType.shopping,
    "bowling_alley" : PlaceType.shopping,
    "bus_station" : PlaceType.location,
    "cafe" : PlaceType.restaurant,
    "campground" : PlaceType.park,
    "car_dealer" : PlaceType.house2,
    "car_rental" : PlaceType.house2,
    "car_repair" : PlaceType.house2,
    "car_wash" : PlaceType.house2,
    "casino" : PlaceType.shopping,
    "cemetery" : PlaceType.castle,
    "church" : PlaceType.castle,
    "city_hall" : PlaceType.twoBuildings,
    "clothing_store" : PlaceType.shopping,
    "convenience_store" : PlaceType.shopping,
    "courthouse" : PlaceType.twoBuildings,
    "dentist" : PlaceType.house2,
    "department_store" : PlaceType.shopping,
    "doctor" : PlaceType.house2,
    "electrician" : PlaceType.house2,
    "electronics_store" : PlaceType.shopping,
    "embassy" : PlaceType.twoBuildings,
    "fire_station" : PlaceType.building,
    "florist" : PlaceType.house,
    "funeral_home" : PlaceType.castle,
    "furniture_store" : PlaceType.shopping,
    "gas_station" : PlaceType.building,
    "gym" : PlaceType.sportsCenter,
    "hair_care" : PlaceType.house2,
    "hardware_store" : PlaceType.shopping,
    "hindu_temple" : PlaceType.castle,
    "home_goods_store" : PlaceType.shopping,
    "hospital" : PlaceType.twoBuildings,
    "insurance_agency" : PlaceType.house2,
    "jewelry_store" : PlaceType.shopping,
    "laundry" : PlaceType.house2,
    "lawyer" : PlaceType.house2,
    "library" : PlaceType.castle,
    "liquor_store" : PlaceType.shopping,
    "local_government_office" : PlaceType.twoBuildings,
    "locksmith" : PlaceType.location,
    "lodging" : PlaceType.location,
    "meal_delivery" : PlaceType.fastFood,
    "meal_takeaway" : PlaceType.fastFood,
    "mosque" : PlaceType.castle,
    "movie_rental" : PlaceType.location,
    "movie_theater" : PlaceType.location,
    "moving_company" : PlaceType.house2,
    "museum" : PlaceType.castle,
    "night_club" : PlaceType.music,
    "painter" : PlaceType.house2,
    "park" : PlaceType.park,
    "parking" : PlaceType.building,
    "pet_store" : PlaceType.shopping,
    "pharmacy" : PlaceType.house2,
    "physiotherapist" : PlaceType.house2,
    "plumber" : PlaceType.house2,
    "police" : PlaceType.twoBuildings,
    "post_office" : PlaceType.twoBuildings,
    "real_estate_agency" : PlaceType.house2,
    "restaurant" : PlaceType.restaurant,
    "roofing_contractor" : PlaceType.house2,
    "rv_park" : PlaceType.park,
    "school" : PlaceType.school,
    "shoe_store" : PlaceType.shopping,
    "shopping_mall" : PlaceType.shopping,
    "spa" : PlaceType.sportsCenter,
    "stadium" : PlaceType.sportsCenter,
    "storage" : PlaceType.building,
    "store" : PlaceType.shopping,
    "subway_station" : PlaceType.building,
    "supermarket" : PlaceType.shopping,
    "synagogue" : PlaceType.castle,
    "taxi_stand" : PlaceType.building,
    "train_station" : PlaceType.building,
    "transit_station" : PlaceType.building,
    "travel_agency" : PlaceType.house2,
    "veterinary_care" : PlaceType.house2,
    "zoo" : PlaceType.location
]

let felipeUser = "S28kuYINNzfrXDfyg9zXGyKzr853"
let asusUser = "oi7p4pL1ZuQvrKRplxcorDv1oI92"
