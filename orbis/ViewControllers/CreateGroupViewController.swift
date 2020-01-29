//
//  CreateGroupViewController.swift
//  orbis
//
//  Created by Rodrigo Brauwers on 07/12/18.
//  Copyright © 2018 Orbis. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxGesture
import RxKeyboard
import RSKImageCropper
import PKHUD

class CreateGroupViewController : OrbisViewController {
    
    @IBOutlet weak var toolbar: DefaultToolbar!
    @IBOutlet weak var imageView: RoundedImageView!
    @IBOutlet weak var cameraIcon: UIImageView!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var lineView2: LineView!
    @IBOutlet weak var textViewPlaceHolder: UILabel!
    @IBOutlet weak var characteristicsLabel: UILabel!
    @IBOutlet weak var characteristicsContainer: UIView!
    @IBOutlet weak var topCostraint: NSLayoutConstraint!
    
    var viewModel: CreateGroupViewModel!
    private var topConstraintInitialConstant: CGFloat!
    private weak var alert: UIAlertController?

    @IBAction func colorClick(_ sender: Any) {
        hideKeyboardFromApplication()
        let vc = createViewController(withInfo: .colors) as! ColorsViewController
        vc.viewModel = viewModel
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func createClick(_ sender: Any) {
        hideKeyboardFromApplication()
        viewModel.save(groupName: nameTextField.text, description: characteristicsLabel.text)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.delegate = self
        nameTextField.delegate = self
        topConstraintInitialConstant = topCostraint.constant
        createButton.makeFontSizeAdjustable()
        nameTextField.setPlaceHolderTextColor(UIColor.darkGray)
        nameTextField.placeholder = Words.chooseGroupName.localized
        textViewPlaceHolder.text = Words.describeGroupCharacteristics.localized
        
        if let g = viewModel.group {
            createButton.titleForNormal = Words.saveChanges.localized.uppercased()
            textViewPlaceHolder.isHidden = true
            characteristicsLabel.text = g.description
            nameTextField.text = g.name
            paintBackground(solidColorIndex: g.colorIndex)
            cameraIcon.isHidden = true
            imageView.loadGroupImage(group: g)
        }
        else {
            createButton.titleForNormal = Words.createNewGroup.localized.uppercased()
        }
        
        observeDefaultSubject(subject: viewModel.subject)
        
        imageView.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { gesture in
                self.showImageAlertController()
            })
            .disposed(by: bag)
        
        characteristicsContainer.rx
            .tapGesture()
            .when(.recognized)
            .subscribe(onNext: { gesture in
                self.showCharacteristicsAlertController()
            })
            .disposed(by: bag)
        
        nameTextField.rx.text
            .orEmpty
            .subscribe(onNext: { text in
                if text.isEmpty {
                    self.domainLabel.text = orbisDomain
                }
                else {
                    let url = text.replacingOccurrences(of: " ", with: "-")
                        .replacingOccurrences(of: "\n", with: "")                    
                    self.domainLabel.text = "https://\(orbisDomain)/g/\(url)"
                }
            }, onError: nil)
            .disposed(by: bag)
        
        viewModel
            .colorIndexSubject
            .subscribe(onNext: { [weak self] colorIndex in
                self?.paintBackground(solidColorIndex: colorIndex)
            }, onError: nil)
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let index = viewModel.colorIndex {
            view.backgroundColor = groupSolidColor(index: index)
        }
    }
    
    override func shouldObserveActiveGroup() -> Bool {
        return false
    }
    
    override func onTaskStarted() {
        HUD.show(.progress)
    }
    
    override func onTaskFinished() {
        HUD.hide()
        navigationController?.popViewController(animated: true)
    }
    
    override func onTaskFailed() {
        HUD.hide()
    }
    
    private func showCharacteristicsAlertController() {
        alert = showAlertWithTextView(
            title: Words.describeGroupCharacteristics.localized,
            placeholder: "",
            leftButtonTitle: Words.cancel.localized,
            rightButtonTitle: Words.ok.localized,
            initialText: characteristicsLabel.text,
            rightActionEnabled: true,
            textViewDelegate: self,
            rightBlock: { [weak self] text in
                let str = text ?? ""
                self?.characteristicsLabel.text = str
                self?.textViewPlaceHolder.isHidden = !str.isEmpty
            }
        )
    }
    
    private func showImageAlertController() {
        let alert = UIAlertController(title: Words.chooseImage.localized, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: Words.camera.localized, style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: Words.gallery.localized, style: .default, handler: { _ in
            self.openGallery()
        }))
        
        alert.addAction(UIAlertAction.init(title: Words.cancel.localized, style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
        }

        self.present(alert, animated: true, completion: nil)
    }
    
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else {
            showOkAlert(title: Words.warning.localized, msg: Words.cameraNotAvailable.localized)
        }
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
}

extension CreateGroupViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            picker.dismiss(animated: false, completion: { () -> Void in
                var imageCropVC : RSKImageCropViewController!
                imageCropVC = RSKImageCropViewController(image: image, cropMode: RSKImageCropMode.circle)
                imageCropVC.delegate = self
                self.navigationController?.pushViewController(imageCropVC, animated: true)
            })
        }
        else {
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
}

extension CreateGroupViewController : RSKImageCropViewControllerDelegate {
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        viewModel.image = croppedImage
        imageView.image = croppedImage
        cameraIcon.isHidden = true
        navigationController?.popViewController(animated: true)
    }
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        navigationController?.popViewController(animated: true)
    }
    
    func imageCropViewControllerDidDisplayImage(_ controller: RSKImageCropViewController) {
        
    }
    
}

extension CreateGroupViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension CreateGroupViewController : UITextViewDelegate {
    
}

extension CreateGroupViewController: KeyboardToolbarDelegate {
    
    func keyboardToolbar(button: UIBarButtonItem, type: KeyboardToolbarButton, tappedIn toolbar: KeyboardToolbar) {

    }

}
