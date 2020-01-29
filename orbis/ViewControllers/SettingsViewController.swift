//
//  SettingsViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 19/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import StoreKit
import RxSwift
import RxCocoa
import Kingfisher
import MKProgress

class SettingsViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: TitleToolbar!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var profileLabel: SectionLabel!
    @IBOutlet weak var socialLabel: SectionLabel!
    @IBOutlet weak var settingsLabel: SectionLabel!
    @IBOutlet weak var orbisLabel: SectionLabel!
    
    @IBOutlet weak var changePhotoLabel: UILabel!
    @IBOutlet weak var userImageView: RoundedImageView!
    @IBOutlet weak var usernameField: FormTextField!
    @IBOutlet weak var emailField: FormTextField!
    @IBOutlet weak var pwdField: FormTextField!

    @IBOutlet weak var socialSubSection0: UILabel!
    @IBOutlet weak var socialSubSection1: UILabel!
    @IBOutlet weak var socialSubSection2: UILabel!
    @IBOutlet weak var socialSubSection3: UILabel!
    @IBOutlet weak var socialSubSection4: UILabel!
    
    @IBOutlet weak var socialExpandButton0: UIButton!
    @IBOutlet weak var socialExpandButton1: UIButton!
    @IBOutlet weak var socialExpandButton2: UIButton!
    @IBOutlet weak var socialExpandButton3: UIButton!
    @IBOutlet weak var socialExpandButton4: UIButton!
    
    @IBOutlet weak var socialTableView0: UITableView!
    @IBOutlet weak var socialTableView1: UITableView!
    @IBOutlet weak var socialTableView2: UITableView!
    @IBOutlet weak var socialTableView3: UITableView!
    @IBOutlet weak var socialTableView4: UITableView!
    
    @IBOutlet weak var languageButton: OutlineButton!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var notificationsLabel: UILabel!
    @IBOutlet weak var unitSegmentedControl: UISegmentedControl!
    @IBOutlet weak var notificationsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var resetButton: OutlineButton!
    
    @IBOutlet weak var feedbackButton: OutlineButton!
    @IBOutlet weak var rateButton: OutlineButton!
    @IBOutlet weak var termsButton: OutlineButton!
    @IBOutlet weak var privacyButton: OutlineButton!
    @IBOutlet weak var logoutButton: OutlineButton!
    
    private let settingsViewModel = SettingsViewModel()
    private let registerViewModel = RegisterViewModel()
    private var user: OrbisUser!
    private weak var alert: UIAlertController?
    
    private lazy var rolesViewModel: RolesViewModel = { [unowned self] in return RolesViewModel.instance() }()
    
    private lazy var reportViewModel: ReportViewModel = { [unowned self] in return ReportViewModel() }()
    
    private lazy var expandButtons: [UIButton] = { [unowned self] in
        return [socialExpandButton0, socialExpandButton1, socialExpandButton2, socialExpandButton3, socialExpandButton4]
    }()
    
    private lazy var socialTableViews: [UITableView] = { [unowned self] in
        return [socialTableView0, socialTableView1, socialTableView2, socialTableView3, socialTableView4]
    }()
    
    private lazy var socialCellTypes: [Cells] = {
        return [Cells.settingsGroupCell, Cells.settingsAdminCell, Cells.settingsPlaceCell, Cells.settingsPostCell, Cells.settingsGroupCell]
    }()
    
    private var socialDataSources = [UITableViewDataSource]()
    private let socialRowHeight: CGFloat = 100.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        user = UserDefaultsRepository.instance().getMyUser()
        if user == nil {
            navigationController?.popViewController()
            return
        }
        
        settingsViewModel.user = user
        
        toolbar.label.text = Words.settings.localized
        toolbar.delegate = self
        
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20.0, right: 0)
        
        let fields = [usernameField, emailField, pwdField]
        for i in 0...fields.count-1 {
            let field = fields[i]
            field?.textField.delegate = self
            field?.textField.isUserInteractionEnabled = false
            field?.textField.textAlignment = .left
            field?.tag = i
        }
        
        for i in 0...expandButtons.count-1 {
            let button = expandButtons[i]
            button.tintColor = UIColor.darkGray
            button.setTitle(nil, for: .normal)
            button.setTitle(nil, for: .selected)
            button.setImage(UIImage(named: "baseline_add_black_48pt"), for: .normal)
            button.setImage(UIImage(named: "baseline_remove_black_48pt"), for: .selected)
            button.tag = i
            
            button.rx.tap
                .bind { [weak self] in
                    self?.toggleSocialSection(index: i)
                }
                .disposed(by: bag)
        }
        
        let scAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        
        unitSegmentedControl.tintColor = UIColor(rgba: "#D9D9D9")
        unitSegmentedControl.setTitleTextAttributes(scAttributes, for: .normal)
        unitSegmentedControl.setTitleTextAttributes(scAttributes, for: .selected)
        unitSegmentedControl.segmentTitles = [Words.miles.localized.uppercased(), Words.km.localized.uppercased()]
        unitSegmentedControl.selectedSegmentIndex = user.unit == OrbisUnit.miles.rawValue ? 0 : 1

        notificationsSegmentedControl.segmentTitles = [Words.on.localized.uppercased(), Words.off.localized.uppercased()]
        notificationsSegmentedControl.tintColor = UIColor(rgba: "#D9D9D9")
        notificationsSegmentedControl.setTitleTextAttributes(scAttributes, for: .normal)
        notificationsSegmentedControl.setTitleTextAttributes(scAttributes, for: .selected)
        notificationsSegmentedControl.selectedSegmentIndex = user.pushNotificationsEnabled ? 0 : 1
        
        usernameField.setText(text: user.username, placeholder: nil)
        emailField.setText(text: user.email, placeholder: nil)
        pwdField.setText(text: "xxxxxxxx", placeholder: nil)
        
        languageButton.setTitle(Words.language.localized, for: .normal)
        feedbackButton.setTitle(Words.feedback.localized, for: .normal)
        rateButton.setTitle(Words.rateApp.localized, for: .normal)
        resetButton.setTitle(Words.resetSettings.localized, for: .normal)
        termsButton.setTitle(Words.termsOfService.localized, for: .normal)
        privacyButton.setTitle(Words.privacyPolicy.localized, for: .normal)
        logoutButton.setTitle(Words.logout.localized, for: .normal)
        
        profileLabel.text = Words.profile.localized
        changePhotoLabel.text = Words.changePhoto.localized
        settingsLabel.text = Words.settings.localized
        socialLabel.text = Words.socialAndSubscriptions.localized
        socialSubSection0.text = Words.changeAndManageGroups.localized
        socialSubSection1.text = Words.manageGroups.localized
        socialSubSection2.text = Words.placesYouFollow.localized
        socialSubSection3.text = Words.myPosts.localized
        socialSubSection4.text = Words.mySubscriptions.localized
        unitLabel.text = Words.unit.localized.capitalized
        notificationsLabel.text = Words.pushNotifications.localized.capitalized
        
        socialDataSources.append(SettingsGroupsDataSource(viewModel: settingsViewModel, delegate: self, section: 0, rolesViewModel: RolesViewModel.instance()))
        socialDataSources.append(SettingsAdminDataSource(viewModel: settingsViewModel, delegate: self, section: 1))
        socialDataSources.append(SettingsPlacesDataSource(viewModel: settingsViewModel, delegate: self, section: 2, rolesViewModel: RolesViewModel.instance()))
        socialDataSources.append(SettingsPostsDataSource(viewModel: settingsViewModel, delegate: self, section: 3))
        socialDataSources.append(SettingsGroupsDataSource(viewModel: settingsViewModel, delegate: self, section: 4, rolesViewModel: RolesViewModel.instance()))
        
        for i in 0...socialTableViews.count-1 {
            let tableView = socialTableViews[i]
            
            if i == 3 {
                tableView.rowHeight = 60
                tableView.separatorInset = UIEdgeInsets.zero
                tableView.allowsSelection = true
            }
            else {
                tableView.rowHeight = socialRowHeight
                tableView.separatorStyle = .none
                tableView.allowsSelection = false
            }
            
            tableView.removeTableHeaderView()
            tableView.hideUndesiredSeparators()
            tableView.register(cell: socialCellTypes[i])
            tableView.dataSource = socialDataSources[i]
            tableView.delegate = self
        }
        
        userImageView.kf.indicatorType = IndicatorType.activity
        loadUserImage()
        
        userImageView.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in self?.openGallery() })
            .disposed(by: bag)

        changePhotoLabel.rx.tapGesture()
            .when(.recognized)
            .subscribe(onNext: { [weak self] _ in self?.openGallery() })
            .disposed(by: bag)
        
        languageButton.rx.tap
            .bind { [weak self] in
                self?.showLanguagesAlertController()
            }
            .disposed(by: bag)
        
        termsButton.rx.tap
            .bind {
                UIApplication.shared.open(tosPage, options: [:])
            }
            .disposed(by: bag)
        
        privacyButton.rx.tap
            .bind {
                UIApplication.shared.open(policyPage, options: [:])
            }
            .disposed(by: bag)
        
        logoutButton.rx.tap
            .bind { [weak self] in
                self?.registerViewModel.signOut()
            }
            .disposed(by: bag)
        
        rateButton.rx.tap
            .bind {
                if #available( iOS 10.3,*){
                    SKStoreReviewController.requestReview()
                }
            }
            .disposed(by: bag)

        feedbackButton.rx.tap
            .bind { [weak self] in
                self?.showFeedbackAlert()
            }
            .disposed(by: bag)
        
        resetButton.rx.tap
            .bind { [weak self] in
                // TODO KINE: reset config notImplemented
                self?.showOkAlert(title: Words.error.localized, msg: Words.notImplemented.localized)
            }
            .disposed(by: bag)
        
        unitSegmentedControl.rx.value
            .subscribe(onNext: { [weak self] index in
                self?.settingsViewModel.save(unit: index == 0 ? OrbisUnit.miles : OrbisUnit.km)
            })
            .disposed(by: bag)
        
        notificationsSegmentedControl.rx.value
            .subscribe(onNext: { [weak self] index in
                self?.settingsViewModel.save(notificationsEnabled: index == 0)
            })
            .disposed(by: bag)
        
        settingsViewModel.reloadSectionSubject
            .subscribe(onNext: { [weak self] sections in
                sections.forEach {
                    self?.socialTableViews[$0].reloadData()
                }
            })
            .disposed(by: bag)

        settingsViewModel.tableOperationSubject
            .subscribe(onNext: { [weak self] operation in
                self?.handleTableOperation(operation: operation, tableView: nil)
            })
            .disposed(by: bag)
        
        settingsViewModel.loadPostWrapperTaskSubject
            .subscribe(onNext: { task in
                switch task {
                case .taskStarted:
                    MKProgress.show()
                default:
                    MKProgress.hide()
                }
            })
            .disposed(by: bag)
        
        rolesViewModel
            .roleByPlaceChangedSubject
            .subscribe(onNext: { [weak self] placeKey in
                guard
                    let this = self,
                    let index = this.settingsViewModel.indexOf(placeKey: placeKey, inSection: 2)
                else {
                    return
                }
                
                this.socialTableView2.reloadRows(at: [index.toIndexPath()], with: .none)
            })
            .disposed(by: bag)
        
        observeDefaultSubject(subject: registerViewModel.subject)
        observeDefaultSubject(subject: settingsViewModel.anySubject)
    }
    
    private func loadUserImage(image: UIImage? = nil) {
        userImageView.loadUserImage(image: image, user: user, activeGroup: UserDefaultsRepository.instance().getActiveGroup())
    }
    
    private func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            showOkAlert(title: Words.warning.localized, msg: Words.galleryNotAvailable.localized)
        }
    }
    
    private func showLanguagesAlertController() {
        let ac = UIAlertController(title: nil, message: Words.chooseYourLanguage.localized, preferredStyle: .actionSheet)
        
        for language in OrbisLanguage.allCases {
            ac.addAction(UIAlertAction(title: language.title(), style: .default, handler: { [weak self] (action: UIAlertAction) in
                self?.languageChoosed(language: language)
            }))
        }

        ac.addAction(UIAlertAction(title: Words.cancel.localized, style: .cancel))
        self.present(ac, animated: true, completion: nil)
    }
    
    private func languageChoosed(language: OrbisLanguage) {
        UserDefaultsRepository.instance().setLanguage(language: language)
        appDelegate().reloadApplication(navController: navigationController)
    }
    
    private func toggleSocialSection(index: Int) {
        let button = expandButtons[index]
        let tableView = socialTableViews[index]
        let constraint = tableView.findConstraint(layoutAttribute: .height)

        if settingsViewModel.isExpanded(section: index) {
            settingsViewModel.expandedSocialSections.remove(index)
            constraint?.constant = 0
            button.setImage(UIImage(named: "baseline_add_black_48pt"), for: .normal)
        }
        else {
            settingsViewModel.expandedSocialSections.insert(index)
            constraint?.constant = settingsViewModel.numberOfItemsOfSocialSection(section: index).cgFloat * socialRowHeight
            button.setImage(UIImage(named: "baseline_remove_black_48pt"), for: .normal)
        }
        
        view.layoutIfNeeded()
        tableView.reloadData()
    }
    
    override func handleTableOperation(operation: TableOperation, tableView: UITableView?) {
        if let op = operation as? TableOperation.DeleteOperation {
            mainAsync {
                self.socialTableViews[op.section].deleteRows(at: [op.index.toIndexPath()], with: .automatic)
            }
        }
        else if let op = operation as? TableOperation.UpdateOperation {
            guard let paths = op.indexPaths else {
                return
            }
            
            mainAsync {
                paths.forEach { path in
                    self.socialTableViews[path.section].reloadData()
                }
            }
        }
        else {
            super.handleTableOperation(operation: operation, tableView: tableView)
        }
    }
    
    private func showFeedbackAlert() {
        alert = showAlertWithTextField(
            title: Words.enterFeedbackMessage.localized,
            placeholder: Words.typeHere.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightActionEnabled: true,
            textFieldDelegate: self,
            rightBlock: { [weak self] text in
                self?.reportViewModel.saveFeedback(message: text)
            }
        )
    }
}

extension SettingsViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var resign = true
        
        if let formView = textField.superview as? FormTextField {
            let nextTag = formView.tag + 1
            if let nextResponder = textField.superview?.superview?.viewWithTag(nextTag) as? FormTextField {
                resign = true
                nextResponder.textField.becomeFirstResponder()
            }
        }
        
        if resign {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
}


extension SettingsViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            loadUserImage(image: image)
            settingsViewModel.saveImage(image: image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}

extension SettingsViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == socialTableView3 {
            if let post = settingsViewModel.getItem(section: 3, row: indexPath.row) as? OrbisPost {
                settingsViewModel.loadPostWrapper(post: post)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}

extension SettingsViewController : SettingsCellDelegate {
    func groupClick(cell: SettingsCell?) {
        if let c = cell as? SettingsGroupCell {
            guard
                let index = socialTableView0.indexPath(for: c),
                let g = settingsViewModel.getItem(section: 0, row: index.row) as? Group
            else {
                return
            }
            handleNavigation(navigation: Navigation.group(group: g))
        }
        else if let c = cell as? SettingsAdminCell {
            guard
                let index = socialTableView1.indexPath(for: c),
                let g = settingsViewModel.getItem(section: 1, row: index.row) as? Group
            else {
                return
            }
            handleNavigation(navigation: Navigation.group(group: g))
        }
        else if let c = cell as? SettingsPlaceCell {
            guard
                let index = socialTableView2.indexPath(for: c),
                let w = settingsViewModel.getItem(section: 2, row: index.row) as? PlaceWrapper,
                let g = w.group
            else {
                return
            }
            handleNavigation(navigation: Navigation.group(group: g))
        }
    }
    
    func placeClick(cell: SettingsCell?) {
        if let c = cell as? SettingsPlaceCell {
            guard
                let index = socialTableView2.indexPath(for: c),
                let w = settingsViewModel.getItem(section: 2, row: index.row) as? PlaceWrapper
            else {
                return
            }
            handleNavigation(navigation: Navigation.place(placeWrapper: w))
        }
    }
    
    func editClick(cell: SettingsAdminCell?) {
        guard
            let c = cell,
            let index = socialTableView1.indexPath(for: c),
            let g = settingsViewModel.getItem(section: 1, row: index.row) as? Group
        else {
            return
        }

        handleNavigation(navigation: .editGroup(group: g))
    }
    
    func changeClick(cell: SettingsGroupCell?) {
        print2("changeClick")
        
        guard
            let c = cell,
            let index = socialTableView0.indexPath(for: c),
            let g = settingsViewModel.getItem(section: 0, row: index.row) as? Group
        else {
            return
        }
        
        HelperRepository.instance().setActiveGroup(group: g, updateUser: true)
    }
    
    func leaveClick(cell: SettingsGroupCell?) {
        print2("leaveClick")
        
        guard
            let c = cell,
            let index = socialTableView0.indexPath(for: c),
            let g = settingsViewModel.getItem(section: 0, row: index.row) as? Group
        else {
            return
        }
        
        rolesViewModel.removeMemberRole(group: g)
    }
    
    func followClick(cell: SettingsPlaceCell?) {
        guard
            let c = cell,
            let index = socialTableView2.indexPath(for: c),
            let w = settingsViewModel.getItem(section: 2, row: index.row) as? PlaceWrapper
        else {
            return
        }
        
        print2("followClick")
        rolesViewModel.toggleFollowRole(placeKey: w.place.key)
    }
    
    func dotsClick(cell: SettingsPostCell?) {
        guard
            let cell = cell,
            let indexPath = socialTableView3.indexPath(for: cell),
            let post = settingsViewModel.getItem(section: 3, row: indexPath.row) as? OrbisPost
        else {
            return
        }
        
        let vc = createViewController(withInfo: .settingsPostMenu) as! SettingsPostMenuViewController
        vc.viewModel = settingsViewModel
        vc.post = post
        vc.preferredContentSize = CGSize(width: 200, height: SettingsPostMenuOptions.allCases.count*50)
        showPopup(vc, sourceView: cell.contentView)
    }
    
}
