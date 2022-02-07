//
//  Copyright (C) 2021 Parrot Drones SAS.
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

/// Display buttons for remote details screen.
final class RemoteDetailsButtonsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var currentDroneButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var calibrationButtonView: DeviceDetailsButtonView!
    @IBOutlet private weak var softwareVersionButtonView: DeviceDetailsButtonView!

    // MARK: - Private Properties
    private var viewModel: RemoteDetailsButtonsViewModel = RemoteDetailsButtonsViewModel()
    private weak var coordinator: RemoteCoordinator?

    // MARK: - Private Enums
    private enum Constants {
        static let minimumBatteryLevel: Double = 5.0
    }

    // MARK: - Setup
    static func instantiate(coordinator: RemoteCoordinator) -> RemoteDetailsButtonsViewController {
        let viewController = StoryboardScene.RemoteDetailsButtons.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension RemoteDetailsButtonsViewController {
    @IBAction func droneButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyRemoteInfosButton.remoteConnectToDrone.name,
                             newValue: nil,
                             logType: .button)
        coordinator?.startDronesList()
    }

    @IBAction func calibrationButtonTouchedUpInside(_ sender: Any) {
        coordinator?.startCalibration()
    }

    @IBAction func softwareVersionButtonTouchedUpInside(_ sender: Any) {
        if viewModel.isBatteryLevelTooLow {
            let percent = Constants.minimumBatteryLevel.asPercent()
            showErrorAlert(title: L10n.remoteUpdateInsufficientBatteryTitle,
                           message: L10n.remoteUpdateInsufficientBatteryDescription(percent))
        } else if viewModel.isDroneFlying() {
            showErrorAlert(title: L10n.deviceUpdateImpossible,
                           message: L10n.deviceUpdateDroneFlying)
        } else {
            coordinator?.startUpdate()
        }
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsButtonsViewController {
    /// Inits the view.
    func initView() {
        currentDroneButtonView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        currentDroneButtonView.addShadow(shadowColor: ColorName.whiteAlbescent.color)
        calibrationButtonView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        calibrationButtonView.addShadow(shadowColor: ColorName.whiteAlbescent.color)
        softwareVersionButtonView.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        softwareVersionButtonView.addShadow(shadowColor: ColorName.whiteAlbescent.color)
    }

    /// Inits the view model.
    func initViewModel() {

        viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state: state)
        }
        updateView(state: viewModel.state.value)
    }

    /// Updates the view according to view model changement.
    ///
    /// - Parameters:
    ///     - state: remote details state
    func updateView(state: RemoteDetailsButtonsState) {
        updateCalibrationView(state: state)
        updateDroneView(state: state)
        updateSoftwareView(state: state)
    }

    /// Updates drone view.
    ///
    /// - Parameters:
    ///     - state: remote details buttons state
    func updateDroneView(state: RemoteDetailsButtonsState) {
        currentDroneButtonView.model = state.droneStatusModel
        currentDroneButtonView.isEnabled = state.remoteControlConnectionState?.isConnected() == true
    }

    /// Updates remote software view.
    ///
    /// - Parameters:
    ///     - state: remote details buttons state
    func updateSoftwareView(state: RemoteDetailsButtonsState) {
        softwareVersionButtonView.model = state.softwareModel
        softwareVersionButtonView.isEnabled = state.needUpdate
            && (state.needDownload || state.remoteControlConnectionState?.isConnected() == true)
    }

    /// Updates calibration view.
    ///
    /// - Parameters:
    ///     - state: remote details buttons state
    func updateCalibrationView(state: RemoteDetailsButtonsState) {
        calibrationButtonView.model = state.calibrationModel
        calibrationButtonView.isEnabled = state.needCalibration
    }

    /// Present a common alert in case of update error.
    ///
    /// - Parameters:
    ///     - title: alert title
    ///     - message: alert description
    func showErrorAlert(title: String, message: String) {
        let cancelAction = AlertAction(title: L10n.ok,
                                       actionHandler: nil)

        let alert = AlertViewController.instantiate(title: title,
                                                    message: message,
                                                    cancelAction: cancelAction,
                                                    validateAction: nil)
        self.present(alert, animated: true, completion: nil)
    }
}
