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

/// HUD Bottom bar level view.
/// Can display level one views like SegmentedBar.

final class BottomBarLevelViewController: UIViewController {
    // MARK: - Private Properties
    private var levelView: UIView?
    private var imagingSettingsBarViewController: ImagingSettingsBarViewController?

    // MARK: - Override Properties
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
}

// MARK: - Internal Funcs
extension BottomBarLevelViewController {
    /// Add segmented bar view.
    ///
    /// - Parameters:
    ///     - viewModel: model representing the contents
    func addSegmentedBar<T: BarButtonState>(viewModel: BarButtonViewModel<T>) {
        removeLevelView()
        removeImagingSettingsBar()
        let segmentedBarView = SegmentedBarView<T>()
        segmentedBarView.viewModel = viewModel
        view.addWithConstraints(subview: segmentedBarView)
        levelView = segmentedBarView
    }

    /// Add imaging settings bar.
    ///
    /// - Parameters:
    ///     - delegate: Bar container delegate
    func addImagingSettingsBar(delegate: BottomBarContainerDelegate? = nil) {
        removeLevelView()
        removeImagingSettingsBar()
        let imagingSettingsBarVC = ImagingSettingsBarViewController.instantiate(delegate: delegate)
        imagingSettingsBarViewController = imagingSettingsBarVC
        self.add(imagingSettingsBarVC)
    }

    /// Check if current segmented bar view is of the same type as given view model type.
    ///
    /// - Parameters:
    ///    - viewModel: the view model
    func isSameBarDisplayed<T: BarButtonState>(viewModel: BarButtonViewModel<T>) -> Bool {
        return levelView is SegmentedBarView<T>
            || (viewModel is CameraWidgetViewModel && imagingSettingsBarViewController != nil)
    }

    /// Remove active view.
    func removeLevelView() {
        levelView?.removeFromSuperview()
        levelView = nil
    }

    /// Remove imaging settings bar.
    func removeImagingSettingsBar() {
        imagingSettingsBarViewController?.remove()
        imagingSettingsBarViewController = nil
    }
}

// MARK: - Private Funcs
private extension BottomBarLevelViewController {
    /// Initializes interfaces.
    func initUI() {
        self.view.translatesAutoresizingMaskIntoConstraints = false
        // Sets up corners
        self.view.customCornered(corners: [.allCorners], radius: Style.fitExtraLargeCornerRadius)
    }
}
