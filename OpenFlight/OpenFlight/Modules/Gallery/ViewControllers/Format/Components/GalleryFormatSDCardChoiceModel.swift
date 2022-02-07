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

/// Model for SD card format choice view.
struct GalleryFormatSDCardChoiceModel {

    // MARK: - Internal Properties
    /// Choice image.
    var image: UIImage
    /// Choice main text.
    var text: String
    /// Choice main text color.
    var textColor: ColorName
    /// Choice subtitle text.
    var subText: String?
    /// Choice subtitle text color.
    var subTextColor: ColorName

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - image: image.
    ///    - text: main text.
    ///    - textColor: main text color.
    ///    - subText: subtitle text.
    ///    - subTextColor: subtitle text color.
    init(image: UIImage,
         text: String,
         textColor: ColorName = ColorName.white,
         subText: String? = nil,
         subTextColor: ColorName = ColorName.white50) {
        self.image = image
        self.text = text
        self.textColor = textColor
        self.subText = subText
        self.subTextColor = subTextColor
    }
}
