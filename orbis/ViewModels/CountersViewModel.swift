//
//  CountersViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 14/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation

class CountersViewModel : OrbisViewModel {
    
    override fileprivate init() {
        super.init()
    }
    
    private static var shared: CountersViewModel = {
        return CountersViewModel()
    }()
    
    static func instance() -> CountersViewModel {
        return CountersViewModel.shared
    }
    
}
