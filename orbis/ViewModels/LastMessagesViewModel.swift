//
//  LastMessagesViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 28/01/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import RxSwift

class LastMessagesViewModel : OrbisViewModel {
    
    let defaultSubject = PublishSubject<Any>()
    private var lastMessages = [ChatMessageWrapper]()
    private(set) var filteredLastMessage = [ChatMessageWrapper]()
    private lazy var myUser: OrbisUser? = { return UserDefaultsRepository.instance().getMyUser() } ()
    
    init(userViewModel: UserViewModel) {
        super.init()
        if userViewModel.isMyUser {
            loadLastMessages(user: userViewModel.user)
        }
    }
    
    private func loadLastMessages(user: OrbisUser) {
        ChatDAO.loadLastMessages(userId: user.uid)
            .subscribe(onNext: { [weak self] lastMessages in
                print2("Loaded \(lastMessages.count) lastMessages")
                guard let this = self else { return}
                this.lastMessages = lastMessages
                this.filteredLastMessage = lastMessages
                this.defaultSubject.onNext(OrbisAction.taskFinished)
                }, onError: { [weak self] error in
                    print2(error)
                    self?.defaultSubject.onNext((OrbisAction.taskFailed, Words.errorGeneric))
            })
            .disposed(by: bag)
    }

    func messageIsFromMe(wrapper: ChatMessageWrapper) -> Bool {
        return wrapper.sender.uid == myUser?.uid
    }
}
