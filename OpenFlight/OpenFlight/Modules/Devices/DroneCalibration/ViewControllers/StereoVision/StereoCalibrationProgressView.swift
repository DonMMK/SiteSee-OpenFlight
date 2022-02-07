// Copyright (C) 2021 Parrot Drones SAS
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

import Foundation
import Combine
import UIKit
import Reusable
import GroundSdk

private extension ULogTag {
     static let tag = ULogTag(name: "StereoCalibrationProgressView")
}

class StereoCalibrationProgressView: UIView, NibOwnerLoadable {

    // MARK: - Outlet

    @IBOutlet weak var missionStateLabel: UILabel!
    @IBOutlet weak var progressViewContainer: UIView!
    @IBOutlet weak var calibrationTitle: UILabel!
    @IBOutlet weak var finishedButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var calibrationCompleteImageView: UIImageView!
    @IBOutlet weak var landingButton: UIButton!

    private var progressView = CircleProgressView()
    private var cancellables = Set<AnyCancellable>()
    private var stereoCalibViewModel: StereoCalibrationViewModel!

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    // MARK: - Static func

    static func instantiateView(viewModel: StereoCalibrationViewModel) -> StereoCalibrationProgressView {
        let view = StereoCalibrationProgressView()
        view.stereoCalibViewModel = viewModel
        view.bindViewModel()
        view.setupUI()

        return view
    }
}

// MARK: - UI Setup

private extension StereoCalibrationProgressView {

    /// Initializes the UI.
    func setupUI() {
        progressViewContainer.addWithConstraints(subview: progressView)
        progressView.backgroundColor = .clear

        finishedButton.cornerRadiusedWith(backgroundColor: ColorName.emerald.color, radius: Style.largeCornerRadius)
    }

    /// Loads the view from a xib.
    func commonInit() {
        self.loadNibContent()
    }

    /// Binds the view model to the view.
    func bindViewModel() {
        stereoCalibViewModel.calibrationStateMessage
            .compactMap { $0 }
            .sink { [unowned self] calibrationMessage in
                missionStateLabel.text = calibrationMessage
            }
            .store(in: &cancellables)

        stereoCalibViewModel.calibrationPercentage
            .compactMap { $0 }
            .sink { [unowned self] percentage in
                progressView.setProgress(percentage/100)
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$shouldHideProgressView
            .sink { [unowned self] shouldHideProgressView in
                if shouldHideProgressView == true {
                    progressView.removeFromSuperview()
                }
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$stopButtonHidden
            .sink { [unowned self] stopButtonHidden in
                stopButton.isHidden = stopButtonHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$finishedButtonHidden
            .sink { [unowned self] finishedButtonHidden in
                finishedButton.isHidden = finishedButtonHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$missionStateHidden
            .sink { [unowned self] missionStateHidden in
                missionStateLabel.isHidden = missionStateHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationCompleteImageHidden
            .sink { [unowned self] calibrationCompleteImageHidden in
                calibrationCompleteImageView.isHidden = calibrationCompleteImageHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationTitle
            .sink { [unowned self] title in
                calibrationTitle.text = title
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationTitleColor
            .sink { [unowned self] calibrationTitleColor in
                calibrationTitle.textColor = calibrationTitleColor
            }
            .store(in: &cancellables)

        stereoCalibViewModel.calibrationStateMessage
            .sink { [unowned self] calibrationMessage in
                missionStateLabel.text = calibrationMessage
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$landingButtonHidden
            .sink { [unowned self] landingButtonHidden in
                landingButton.isHidden = landingButtonHidden
            }
            .store(in: &cancellables)

        stereoCalibViewModel.$calibrationMessageColor
            .sink { [unowned self] messageColor in
                missionStateLabel.textColor = messageColor
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action

extension StereoCalibrationProgressView {

    @IBAction func cancelCalibration(_ sender: Any) {
        stereoCalibViewModel.cancelCalibration()
        stereoCalibViewModel.dismissProgressView(endState: .aborted)
    }

    @IBAction func closeAfterCalibration(_ sender: Any) {
        stereoCalibViewModel.dismissProgressView(endState: .noError)
        stereoCalibViewModel.back()
    }

    @IBAction func landingDrone(_ sender: Any) {
        stereoCalibViewModel.landDrone()
    }
}
