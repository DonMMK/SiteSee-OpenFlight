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

/// Gallery Filter Collection View Cell.

final class GalleryFilterCollectionViewCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var image: UIImageView!
    @IBOutlet private weak var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var label: UILabel!

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

// MARK: - Internal Funcs
internal extension GalleryFilterCollectionViewCell {
    /// Setup cell.
    ///
    /// - Parameters:
    ///    - type: Gallery Media Type
    ///    - itemCount: number of item of this type
    ///    - highlight: boolean to determine if we need to apply the highlight theme
    func setup(type: GalleryMediaType, itemCount: Int, highlight: Bool) {
        let tintColor = highlight ? .white : ColorName.defaultTextColor.color
        bgView.cornerRadiusedWith(backgroundColor: (highlight ? ColorName.highlightColor.color : .white),
                                  borderColor: .clear,
                                  radius: Style.mediumCornerRadius,
                                  borderWidth: Style.noBorderWidth)
        image.image = type.filterImage
        image.tintColor = tintColor
        imageWidthConstraint.constant = type.preferredWidth
        imageHeightConstraint.constant = type.preferredHeight
        label.text = "\(itemCount)"
        label.textColor = tintColor
    }
}
