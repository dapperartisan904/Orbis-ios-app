//
//  GroupViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 25/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class GroupViewModel : OrbisViewModel {
    
    let group: Group
    
    let tabSelectedSubject = PublishSubject<GroupTab>()
    
    init(group: Group) {
        self.group = group
        super.init()
    }

    func tabSelected(tab: GroupTab) {
        tabSelectedSubject.onNext(tab)
    }

}
