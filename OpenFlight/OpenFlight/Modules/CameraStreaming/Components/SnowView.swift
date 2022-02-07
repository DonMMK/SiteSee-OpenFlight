// Copyright (C) 2020 Parrot Drones SAS
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

import Reusable

/// The view to supperpose to video view when any drone is connected.

@IBDesignable
final class SnowView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var imageView: UIImageView!

    // MARK: - Override Properties
    /// isHidden: Overriden to add stop / restart snow animation.
    override var isHidden: Bool {
        didSet {
            self.animate(isHidden: isHidden)
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        createImageIfNecessary()
    }

    // MARK: - Funcs
    /// Create animation image if necessary.
    func createImageIfNecessary() {
        if self.imageView.image == nil {
            let animationImages = Asset.SnowView.allValues.compactMap { $0.image }
            self.imageView.image = UIImage.animatedImage(with: animationImages,
                                                         duration: Style.mediumAnimationDuration)
        }
    }
}

// MARK: - Private Funcs
private extension SnowView {
    /// Starts or stops snow animation.
    ///
    /// - Parameters:
    ///    - isHidden: whether animation is hidden or not
    func animate(isHidden: Bool) {
        guard let imageView = imageView else {
            return
        }

        if isHidden {
            imageView.stopAnimating()
        } else {
            createImageIfNecessary()
            imageView.startAnimating()
        }
    }
}
