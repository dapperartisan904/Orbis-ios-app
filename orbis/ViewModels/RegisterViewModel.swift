//
//  RegisterViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 10/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import RxSwift
import RxFirebaseDatabase
import RxFirebaseAuth
import FirebaseDatabase
import FirebaseAuth
import SwifterSwift

class RegisterViewModel : OrbisViewModel {
    
    let subject = PublishSubject<Any>()
    
    func signIn(username: String?, pwd: String?) {
        guard let username = username, !username.isEmpty else {
            subject.onNext(Words.invalidUsername)
            return
        }

        guard let pwd = pwd, !username.isEmpty else {
            subject.onNext(Words.invalidPassword)
            return
        }
        
        var userFromDB: OrbisUser?

        subject.onNext(OrbisAction.taskStarted)
        
        UserDAO
            .findFirstByUsername(username: username)
            .flatMap { (user: OrbisUser?) -> Single<AuthDataResult> in
                guard let email = user?.email else {
                    return Single.error(OrbisErrors.userNotExist)
                }

                userFromDB = user
                return Auth.auth().rx.signIn(withEmail: email, password: pwd)
            }
            .flatMap { _ in
                return GroupDAO.findByKey(groupKey: userFromDB?.activeGroupId)
            }
            .subscribe(onSuccess: { [weak self] (group: Group?) in
                HelperRepository.instance().onRegistered(user: userFromDB, group: group)
                self?.subject.onNext((OrbisAction.taskFinished, OrbisAction.signIn))
                print2("sigin finished")
            }, onError: { [weak self] (error: Error) in
                print2("sign in error")
                print2(error)
                self?.subject.onNext((OrbisAction.taskFailed, error))
            })
            .disposed(by: bag)
    }
    
    private func signInAdditionalStepObservable(user: OrbisUser) -> Single<Bool> {
        return GroupDAO.findByKey(groupKey: user.activeGroupId)
            .flatMap { [weak self] (group : Group?) -> Single<Bool> in
                print2("signInAdditionalStep")
                HelperRepository.instance().onRegistered(user: user, group: group)
                return Single.just(true)
            }
    }
    
    func signUp(username: String?, email: String?, pwd: String?, pwd2: String?) {
        guard let username = username, !username.isEmpty else {
            subject.onNext(Words.invalidUsername)
            return
        }
        
        guard let email = email, email.isValidEmail else {
            subject.onNext(Words.invalidEmail)
            return
        }

        guard let pwd = pwd, pwd.count > 5 else {
            subject.onNext(Words.invalidPassword)
            return
        }
    
        if pwd != pwd2 {
            subject.onNext(Words.invalidRepeatPassword)
            return
        }

        subject.onNext(OrbisAction.taskStarted)
        
        let user = OrbisUser()
        user.username = username
        user.email = email
        user.flavor = orbisFlavor()
        
        if let location = HelperRepository.instance().getLocation() {
            user.coordinates = location
            user.geohash = location.toCLLocationCoordinate2D().geohash()
        }
        
        Auth.auth().rx.createUser(withEmail: email, password: pwd)
            .flatMap { (result: AuthDataResult) -> Single<DatabaseReference> in
                user.uid = result.user.uid
                return UserDAO.save(user: user)
            }
            .flatMap { _ -> Single<Bool> in
                return ChatDAO.saveWelcomeChat(receiverId: user.uid)
            }
            .subscribe(onSuccess: { [weak self] _ in
                HelperRepository.instance().onRegistered(user: user, group: nil)
                self?.subject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                print2("Signup error \(error)")
                self?.subject.onNext((OrbisAction.taskFailed, error))
            })
            .disposed(by: bag)
    }
    
    // Used on login with provider flow
    private func signUpObservable(user: User) -> Single<Bool> {
        let orbisUser = OrbisUser()
        orbisUser.uid = user.uid
        orbisUser.username = user.displayName ?? "[NotAvailable] \(hashValue)"
        orbisUser.email = user.email
        orbisUser.providerImageUrl = user.photoURL?.absoluteString
        orbisUser.flavor = orbisFlavor()
        
        if let location = HelperRepository.instance().getLocation() {
            orbisUser.coordinates = location
            orbisUser.geohash = location.toCLLocationCoordinate2D().geohash()
        }
        
        return UserDAO.save(user: orbisUser)
            .flatMap { _ -> Single<Bool> in
                return ChatDAO.saveWelcomeChat(receiverId: user.uid)
            }
            .flatMap { [weak self] _ -> Single<Bool> in
                HelperRepository.instance().onRegistered(user: orbisUser, group: nil)
                self?.subject.onNext(OrbisAction.signIn)
                return Single.just(true)
            }
    }

    /*
        Contains additional steps after provider login (facebook, twitter) executed with success
     */
    func loginWithProvider(credential: AuthCredential) {
        var firebaseUser: User? = nil
        
        Auth.auth().rx.signInAndRetriveData(with: credential)
            .flatMap { (result : AuthDataResult) -> Single<OrbisUser?> in
                print2("loginWithProvider [1]")
                firebaseUser = result.user
                return UserDAO.load(userId: result.user.uid)
            }
            .flatMap { [weak self] (user : OrbisUser?) -> Single<Bool> in
                guard let this = self else {
                    print2("loginWithProvider [1.5]")
                    return Single.just(false)
                }
                
                if let user = user {
                    print2("loginWithProvider [2]")
                    return this.signInAdditionalStepObservable(user: user)
                }
                else {
                    print2("loginWithProvider [3]")
                    return this.signUpObservable(user: firebaseUser!)
                }
            }
            .subscribe(onSuccess: { [weak self] _ in
                guard let this = self else {
                    print2("loginWithProvider early return")
                    return
                }
                
                print2("loginWithProvider finished with success")
                this.subject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                self?.subject.onNext((OrbisAction.taskFailed, error))
            })
            .disposed(by: bag)
    }
    
    func signOut() {
        var completable = Completable.empty()
        
        // Prevent notifications
        if let user = UserDefaultsRepository.instance().getMyUser() {
            completable = UserDAO.changeSubscriptionToItemsBeingFollowed(userId: user.uid, subscribe: false)
                .andThen(UserDAO.saveFcmToken(userId: user.uid, token: nil))
        }
        
        completable.subscribe(onCompleted: { [weak self] in
            do {
                try Auth.auth().signOut()
                HelperRepository.instance().onLogout()
                self?.subject.onNext(OrbisAction.signOut)
                print("signOut finished")
            }
            catch {
                self?.subject.onNext(error)
            }
        }, onError: { error in
            print2(error)
        })
        .disposed(by: bag)
    }
    
}
