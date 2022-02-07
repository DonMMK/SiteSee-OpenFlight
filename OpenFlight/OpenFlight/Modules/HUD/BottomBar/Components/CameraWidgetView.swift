//
//  Copyright (C) 2020 Parrot Drones SAS.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import UIKit
import Reusable

/// Custom view displaying camera info : ShutterSpeed, EV, resolution, FPS...
final class CameraWidgetView: UIControl, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var cameraWidgetLabel1: UILabel!
    @IBOutlet private weak var cameraWidgetSubLabel1: UILabel!
    @IBOutlet private weak var cameraWidgetSubLabelView: UIView!
    @IBOutlet private weak var cameraWidgetLabel2: UILabel!
    @IBOutlet private weak var macaronImageView: UIImageView!

    // MARK: - Internal Properties
    var model: CameraWidgetState! {
        didSet {
            fill(with: model)
        }
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customInitCameraWidgetView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        customInitCameraWidgetView()
    }
}

// MARK: - Private Funcs
private extension CameraWidgetView {
    func customInitCameraWidgetView() {
        self.loadNibContent()
        cameraWidgetLabel1.textColor = ColorName.defaultTextColor80.color
        cameraWidgetSubLabel1.textColor = ColorName.defaultTextColor80.color
        cameraWidgetSubLabelView.applyCornerRadius(Style.verySmallCornerRadius)
        cameraWidgetLabel2.textColor = ColorName.defaultTextColor.color
    }

    /// Fills the UI elements of the view with given model.
    ///
    /// - Parameters:
    ///    - viewModel: model representing the contents
    func fill(with viewModel: CameraWidgetState) {
        cameraWidgetLabel1.text = model.labelShutterSpeed + " · "
        cameraWidgetSubLabel1.text = model.labelExposureCompensation.uppercased()
        if let labelCameraValue2 = model.labelCameraSpecificProperty2 {
            cameraWidgetLabel2.text = model.labelCameraSpecificProperty1 + " · " + labelCameraValue2
        } else {
            cameraWidgetLabel2.text = model.labelCameraSpecificProperty1
        }

        updateIcon()
        updateTextColor()
        updateBackgroundColor()
    }

    func updateIcon() {
        let photoSignature = model.isPhotoSignatureEnabled
        macaronImageView.isHidden = !photoSignature
        // TODO - uncomment when the given icon is compatible to tint
        // macaronImageView.tintColor = model.isSelected.value ? .white : ColorName.sambuca.color
    }

    func updateTextColor() {
        let isSelected = model.isSelected.value
        cameraWidgetLabel1.textColor = isSelected ? .white : ColorName.defaultTextColor80.color
        cameraWidgetSubLabel1.textColor = model.exposureTextColor
        cameraWidgetLabel2.textColor = isSelected ? .white : ColorName.defaultTextColor.color
    }

    func updateBackgroundColor() {
        let isSelected = model.isSelected.value
        let backgroundColor = isSelected ? ColorName.highlightColor.color : ColorName.white90.color
        customCornered(corners: [.topRight, .bottomRight],
                       radius: Style.largeCornerRadius,
                       backgroundColor: backgroundColor,
                       borderColor: .clear)
        cameraWidgetSubLabelView.backgroundColor = model.exposureBackgroundColor
    }
}
