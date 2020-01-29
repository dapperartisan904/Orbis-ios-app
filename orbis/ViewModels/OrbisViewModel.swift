//
//  OrbisViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import RxSwift

/*
    Should be used as a abstract class
 */
class OrbisViewModel : NSObject {
    
    let bag = DisposeBag()

}

protocol SearchDelegate {
    func search(term: String?)
}
