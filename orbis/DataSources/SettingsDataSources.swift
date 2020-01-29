//
//  SettingsDataSources.swift
//  orbis_sandbox
//
//  Created by Rodrigo Brauwers on 02/03/19.
//  Copyright © 2019 Orbis. All rights reserved.
//

import Foundation
import UIKit

class BaseSettingsSocialDataSource : NSObject {
    
    weak var delegate: SettingsCellDelegate?
    let viewModel: SettingsViewModel
    let section: Int
    
    init(viewModel: SettingsViewModel, delegate: SettingsCellDelegate, section: Int) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.section = section
    }
    
}

class SettingsGroupsDataSource : BaseSettingsSocialDataSource, UITableViewDataSource {
    
    private let rolesViewModel: RolesViewModel
    
    init(viewModel: SettingsViewModel, delegate: SettingsCellDelegate, section: Int, rolesViewModel: RolesViewModel) {
        self.rolesViewModel = rolesViewModel
        super.init(viewModel: viewModel, delegate: delegate, section: section)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsOfSocialSection(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.settingsGroupCell, for: indexPath) as! SettingsGroupCell
        let group = viewModel.getItem(section: section, row: indexPath.row) as? Group
        
        cell.section = section
        cell.delegate = delegate
        cell.groupImageView.loadGroupImage(group: group)
        cell.groupNameLabel.text = group?.name
        cell.changeButton.setTitle(Words.changeGroup.localized, for: .normal)
        cell.leaveButton.setTitle(Words.leaveGroup.localized, for: .normal)
        cell.changeButton.paint(group: nil)
        cell.leaveButton.paint(group: UserDefaultsRepository.instance().getActiveGroup())
        
        return cell
    }
    
}

class SettingsAdminDataSource : BaseSettingsSocialDataSource, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsOfSocialSection(section: self.section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.settingsAdminCell, for: indexPath) as! SettingsAdminCell
        let group = viewModel.getItem(section: section, row: indexPath.row) as? Group

        cell.section = section
        cell.delegate = delegate
        cell.groupImageView.loadGroupImage(group: group)
        cell.groupNameLabel.text = group?.name
        
        return cell
    }
    
}

class SettingsPlacesDataSource : BaseSettingsSocialDataSource, UITableViewDataSource {
    
    private let rolesViewModel: RolesViewModel
    
    init(viewModel: SettingsViewModel, delegate: SettingsCellDelegate, section: Int, rolesViewModel: RolesViewModel) {
        self.rolesViewModel = rolesViewModel
        super.init(viewModel: viewModel, delegate: delegate, section: section)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItemsOfSocialSection(section: self.section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.settingsPlaceCell, for: indexPath) as! SettingsPlaceCell
        
        guard let wrapper = viewModel.getItem(section: section, row: indexPath.row) as? PlaceWrapper else {
            return cell
        }
        
        cell.section = section
        cell.delegate = delegate
        cell.groupImageView.loadGroupImage(group: wrapper.group)
        cell.placeLabel.text = wrapper.place.name
        cell.followButton.bindStatus(status: rolesViewModel.followStatus(placeKey: wrapper.place.key), indicator: cell.followIndicatorView)
        cell.followButton.paint(group: viewModel.activeGroup)
        
        return cell
    }
    
}

class SettingsPostsDataSource : BaseSettingsSocialDataSource, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print2("SettingsPostsDataSource::numberOfRowsInSection section: \(self.section)")
        return viewModel.numberOfItemsOfSocialSection(section: self.section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withCellType: Cells.settingsPostCell, for: indexPath) as! SettingsPostCell
        
        guard
            let post = viewModel.getItem(section: section, row: indexPath.row) as? OrbisPost,
            let type = post.typeEnum()
        else {
            return cell
        }
        
        let timestamp = Double(post.serverTimestamp / 1000)
        
        cell.section = section
        cell.delegate = delegate
        cell.dateLabel.text = Date(timeIntervalSince1970: timestamp).dateTimeString(ofStyle: .medium)
        cell.userLabel.text = viewModel.user.username
        cell.selectionStyle = .none
        
        switch type {
        
        case PostType.text:
            cell.iconView.isHidden = true
            cell.descLabel.isHidden = true
            cell.descLabel2.isHidden = false
            cell.descLabel2.text = post.details
        
        case .images:
            cell.iconView.isHidden = false
            cell.descLabel.isHidden = false
            cell.descLabel2.isHidden = true
            cell.descLabel.text = Words.photo.localized
            cell.iconView.image = UIImage(named: "baseline_photo_camera_white_48pt")

        case .video:
            cell.iconView.isHidden = false
            cell.descLabel.isHidden = false
            cell.descLabel2.isHidden = true
            cell.descLabel.text = Words.video.localized
            cell.iconView.image = UIImage(named: "baseline_videocam_black_48pt")
        
        default:
            break
        }
        
        return cell
    }
    
}
