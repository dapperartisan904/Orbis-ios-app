//
//  AdminDAO.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 06/02/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseDatabase

class AdminDAO {
    
    private static let reference = database().reference(withPath: "admin")
    
    static func observeAdmin() -> Observable<OrbisAdmin?> {
        return reference.rx.observeEvent(.value)
            .map { (snapshot : DataSnapshot) -> OrbisAdmin? in
                return snapshot.firstChild(type: OrbisAdmin.self)
            }
    }
    
}
