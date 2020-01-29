//
//  GeoFireExt.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 20/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import GeoFire
import RxSwift

extension GeoFire {
    
    func setLocationCompletable(key: String, location: Coordinates) -> Single<Bool> {
        return Single<Bool>.create { single in
            self.setLocation(
                location.toCLLocation(),
                forKey: key,
                withCompletionBlock: { error in
                    if let error = error {
                        single(.error(error))
                    }
                    else {
                        single(.success(true))
                    }
                }
            )
            return Disposables.create()
        }
    }
    
    func removeLocationCompletable(key: String) -> Single<Bool> {
        return Single<Bool>.create { single in
            self.removeKey(
                key,
                withCompletionBlock: { error in
                    if let error = error {
                        single(.error(error))
                    }
                    else {
                        single(.success(true))
                    }
                }
            )
            return Disposables.create()
        }
    }
    
}


extension CLLocationCoordinate2D {
    
    func geohash() -> String? {
        return GFGeoHash(location: self, precision: 12)?.geoHashValue
    }
    
}
