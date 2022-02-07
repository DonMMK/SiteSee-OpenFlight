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

/// Custom button for device screens.
final class DeviceButtonView: HighlightableUIControl, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var iconView: UIView!
    @IBOutlet private weak var label: UILabel! {
        didSet {
            label.makeUp(with: .large)
        }
    }

    // MARK: - Internal Properties
    var titleColor: UIColor = UIColor(named: .white) {
        didSet {
            label.textColor = self.titleColor
        }
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitDeviceButtonView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitDeviceButtonView()
    }

    // MARK: - Internal Funcs
    /// Setup the view.
    ///
    /// - Parameters:
    ///     - model: Model representing the button view
    func fill(model: DeviceButtonModel) {
        updateView(model)
    }
}

// MARK: - Private Funcs
private extension DeviceButtonView {
    /// Common init.
    func commonInitDeviceButtonView() {
        self.loadNibContent()
    }

    /// Updates the view.
    ///
    /// - Parameters:
    ///     - model: Model representing the button view
    func updateView(_ model: DeviceButtonModel) {
        label.text = model.label
        iconView.isHidden = model.image == nil
        imageView.image = model.image
    }
}
