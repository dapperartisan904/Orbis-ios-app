//
//  CreateGroupViewModel.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class CreateGroupViewModel : OrbisViewModel {
    
    let group: Group?
    let subject = PublishSubject<Any>()
    let colorIndexSubject = PublishSubject<Int?>()
    
    var image: UIImage?
    
    var colorIndex: Int? {
        didSet {
            colorIndexSubject.onNext(colorIndex)
        }
    }
    
    init(group: Group?) {
        self.group = group
        self.colorIndex = group?.colorIndex
    }
    
    func save(groupName: String?, description: String?) {
        if !commonValidations(groupName: groupName, description: description) {
            return
        }
        
        if let g = group {
            editGroup(group: g, groupName: groupName, description: description)
        }
        else {
            createGroup(groupName: groupName, description: description)
        }
    }
    
    private func editGroup(group: Group, groupName: String?, description: String?) {
        guard let groupKey = group.key else {
            return
        }
        
        guard let colorIndex = colorIndex else {
            subject.onNext(Words.errorChooseColor)
            return
        }
        
        subject.onNext(OrbisAction.taskStarted)
        
        if let image = image {
            S3Repository.instance()
                .upload(image: image, key: S3Folder.groups.uploadKey(cloudKey: groupKey, localFileType: "jpeg"))
        }

        group.name = groupName
        group.description = description
        group.colorIndex = colorIndex
        group.solidColorHex = groupSolidColorHex(index: colorIndex)
        group.strokeColorHex = groupStrokeColorHex(index: colorIndex)
        
        GroupDAO.saveGroup(group: group)
            .subscribe(onSuccess: { [weak self] _ in
                print2("Edit group success")
                self?.subject.onNext(OrbisAction.taskFinished)
                HelperRepository.instance().onGroupEdited(group: group)
            }, onError: {
                [weak self] error in
                print2("Edit group error")
                print2(error)
                self?.subject.onNext(Words.errorGeneric)
            })
            .disposed(by: bag)
    }
    
    private func createGroup(groupName: String?, description: String?) {
        let def = UserDefaultsRepository.instance()
        
        guard let colorIndex = colorIndex else {
            subject.onNext(Words.errorChooseColor)
            return
        }
        
        guard let image = image else {
            subject.onNext(Words.errorSelectGroupPhoto)
            return
        }
        
        guard let location = def.getLocation() else {
            subject.onNext(Words.errorCreateGroupNoLocation)
            return
        }
        
        guard let user = def.getMyUser() else {
            subject.onNext(Words.errorCreateGroupNoUser)
            return
        }
        
        guard let groupKey = GroupDAO.newKey() else {
            subject.onNext(Words.errorGeneric)
            return
        }

        subject.onNext(OrbisAction.taskStarted)

        S3Repository.instance()
            .upload(image: image, key: S3Folder.groups.uploadKey(cloudKey: groupKey, localFileType: "jpeg"))
        
        let group = Group()
        group.key = groupKey
        group.name = groupName
        group.description = description
        group.colorIndex = colorIndex
        group.solidColorHex = groupSolidColorHex(index: colorIndex)
        group.strokeColorHex = groupStrokeColorHex(index: colorIndex)
        group.imageName = "\(groupKey).jpeg"
        group.location = location
        group.geohash = ""
        group.os = "iOS"
        
        GroupDAO
            .createGroup(group: group)
            .flatMap { res in
                RoleDAO.saveRoleInGroup(userId: user.uid, groupId: groupKey, role: Roles.administrator, add: true)
            }
            .flatMap { res in
                RoleDAO.saveRoleInGroup(userId: user.uid, groupId: groupKey, role: Roles.member, add: true)
            }
            .subscribe(onSuccess: { [weak self] value in
                print2("Create group success")
                self?.subject.onNext(OrbisAction.taskFinished)
            }, onError: { [weak self] error in
                print2("Create group error")
                print2(error)
                self?.subject.onNext(Words.errorGeneric)
            })
            .disposed(by: bag)
    }

    /*
        Common validations to create and edit
     */
    private func commonValidations(groupName: String?, description: String?) -> Bool {
        guard let c = groupName?.count, c >= 3 else {
            subject.onNext(Words.invalidGroupName)
            return false
        }
        
        guard let c2 = description?.count, c2 >= groupDescriptionMinLenght else {
            subject.onNext(Words.invalidGroupDescription)
            return false
        }
        
        return true
    }
   
}
