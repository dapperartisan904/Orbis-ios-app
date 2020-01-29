//
//  CreatePlaceStepOne.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 31/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import SwifterSwift

class CreatePlaceStepOneViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: TitleToolbar!
    @IBOutlet weak var selectButton: BottomButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let viewModel = CreatePlaceViewModel()
    private let options = PlaceType.valuesForCreatePlace()
    private var didLayoutSubviews = false
    private var selectedIndex: Int? = 0
    private var alert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        toolbar.label.text = Words.choosePlaceName.localized
        toolbar.delegate = self
        
        selectButton.setTitle(Words.select.localized.uppercased(), for: .normal)
        
        selectButton.rx.tap
            .bind { [weak self] in
                self?.iconSelected()
            }
            .disposed(by: bag)
        
        observeDefaultSubject(subject: viewModel.defaultSubject, onlyIfVisible: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !didLayoutSubviews {
            didLayoutSubviews = true

            DispatchQueue.main.async {
                let cvSize = self.collectionView.frame.size
                let itemSize = CGSize(width: cvSize.width / 3.0 - 1.0, height: cvSize.height / 5.0 - 1.0)
                let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
                layout.itemSize = itemSize
                layout.minimumLineSpacing = 1.0
                layout.minimumInteritemSpacing = 1.0
                layout.footerReferenceSize = CGSize.zero
                layout.headerReferenceSize = CGSize.zero
                layout.sectionInset = UIEdgeInsets.zero
                
                self.collectionView.register(cell: Cells.placeIcon)
                self.collectionView.delegate = self
                self.collectionView.dataSource = self
                self.collectionView.backgroundColor = UIColor.black
                self.collectionView.allowsMultipleSelection = false
                self.collectionView.allowsSelection = true
            }
        }
    }
    
    override func toolbarTitleClick() {
        showPlaceNameAlert()
    }
    
    private func showPlaceNameAlert() {
        alert = showAlertWithTextField(
            title: Words.enterPlaceName.localized,
            placeholder: Words.typeHere.localized,
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            rightActionEnabled: false,
            textFieldDelegate: self,
            rightBlock: { [weak self] text in
                self?.placeNameTyped(text: text)
            }
        )
    }
    
    private func placeNameTyped(text: String?) {
        let placeType = selectedIndex == nil ? nil : options[selectedIndex!]
        viewModel.process(placeType: placeType, placeName: text)
    }
    
    private func iconSelected() {
        if viewModel.placeName == nil {
            showPlaceNameAlert()
        }
        else {
            let placeType = selectedIndex == nil ? nil : options[selectedIndex!]
            viewModel.process(placeType: placeType, placeName: viewModel.placeName)
        }
    }
}

extension CreatePlaceStepOneViewController : UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cells.placeIcon.rawValue, for: indexPath) as! PlaceIconCell
        let selectedColor = groupSolidColor(group: viewModel.activeGroup, defaultColor: UIColor(rgba: tabActiveColor))
        
        cell.backgroundColor = UIColor.white
        cell.cellButton.tintColor = UIColor(rgba: "#BFBFBF")
        cell.cellButton.imageForNormal = UIImage(named: options[indexPath.row].rawValue)
        cell.cellButton.imageForSelected = UIImage(named: options[indexPath.row].rawValue)?.filled(withColor: selectedColor)
        cell.cellButton.isUserInteractionEnabled = false
        cell.cellButton.isSelected = indexPath.row == selectedIndex
        cell.cellButton.imageView?.contentMode = .scaleAspectFit
        
        return cell
    }
    
}

extension CreatePlaceStepOneViewController : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let prevIndex = selectedIndex
        selectedIndex = indexPath.row
        collectionView.reloadItems(indexes: prevIndex, selectedIndex)
        iconSelected()
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
}

extension CreatePlaceStepOneViewController : UICollectionViewDelegateFlowLayout {

}

extension CreatePlaceStepOneViewController : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        alert?.actions[0].isEnabled = (text?.count ?? 0) >= 3
        return true
    }
    
}
