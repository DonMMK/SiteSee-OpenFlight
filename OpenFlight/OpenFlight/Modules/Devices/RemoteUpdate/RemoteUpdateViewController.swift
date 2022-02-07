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

/// Class which displays remote control update.
final class RemoteUpdateViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var sendingStepView: UpdateStepView!
    @IBOutlet private weak var downloadingStepView: UpdateStepView!
    @IBOutlet private weak var rebootingStepView: UpdateStepView!
    @IBOutlet private weak var progressView: RemoteImageView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var continueButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var isUpdateFinished: Bool = false
    private var viewModel: RemoteUpdateViewModel?
    /// Tells whether dowload is the only step during this update.
    private var isDownloadOnly: Bool = false
    /// Tells whether target firmware is already downloaded.
    private var isFirmwareAlreadyDownloaded: Bool = false
    private var isUpdateCancelledAlertShown: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let progressDuration: TimeInterval = 1.0
        static let twoSteps: Int = 2
        static let threeSteps: Int = 3
        static let rebootDuration: TimeInterval = 90.0
        static let afterRebootProgressValue: Int = 95
        static let maxProgressValue: Int = 100
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> RemoteUpdateViewController {
        let viewController = StoryboardScene.RemoteUpdate.remoteUpdate.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.firmwareUpdate,
                             logType: .screen)
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
private extension RemoteUpdateViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        viewModel?.cancelUpdateProcess()
        coordinator?.back()
    }

    @IBAction func stateButtonTouchedUpInside(_ sender: Any) {
        if isUpdateFinished {
            coordinator?.back()
        } else {
            progressView.resetProgress()
            viewModel?.cancelUpdateProcess()
            viewModel?.startUpdateProcess()
        }
    }
}

// MARK: - Private Funcs
/// Common private extension.
private extension RemoteUpdateViewController {
    /// Init the view.
    func initView() {
        titleLabel.text = L10n.remoteUpdateControllerUpdate
        backButton.setTitle(L10n.cancel, for: .normal)
        progressView.updateRemoteImage(image: Asset.Remote.icRemoteUpdate.image)
        continueButton.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color,
                                          borderColor: .clear,
                                          radius: Style.largeCornerRadius)
    }

    /// Update device update steps.
    ///
    /// - Parameters:
    ///     - step: current step of the update
    func updateStepView(_ step: RemoteUpdateStep) {
        switch step {
        case .downloadStarted:
            downloadingStepView.model.state = .doing
        case .downloadCompleted:
            downloadingStepView?.model.state = .done
            if isDownloadOnly {
                isUpdateFinished = true
                updateButtonView()
            } else if viewModel?.state.value.remoteControlConnectionState?.isConnected() == false {
                showUpdateCancelledAlert()
            } else {
                // Launch update when download is finish.
                viewModel?.startUpdateProcess()
            }
        case .updateStarted,
             .uploading:
            downloadingStepView?.model.state = .done
            sendingStepView?.model.state = .doing
        case .processing,
             .rebooting:
            downloadingStepView?.model.state = .done
            sendingStepView?.model.state = .done
            rebootingStepView?.model.state = .doing
        case .updateCompleted:
            rebootingStepView?.model.state = .done
            isUpdateFinished = true
            updateButtonView()
        default:
            break
        }

        backButton.isHidden = !step.canCancelProcess
    }

    /// Update device progress view
    /// according to current progress value and current step of the process.
    ///
    /// - Parameters:
    ///     - step: current step of the update
    ///     - progress: current progress value
    func updateProgressView(step: RemoteUpdateStep?, progress: Int?) {
        switch step {
        case .downloadStarted:
            updateProgress(progress: progress)
        case .downloadCompleted:
            if isDownloadOnly {
                progressView.lockCompleteProgress(Constants.maxProgressValue, duration: Constants.progressDuration)
            } else {
                updateProgress(progress: progress)
            }
        case .updateStarted,
             .uploading:
            updateProgress(progress: progress)
        case .processing,
             .rebooting:
            progressView.lockCompleteProgress(Constants.afterRebootProgressValue, duration: Constants.rebootDuration)
        case .updateCompleted:
            progressView.lockCompleteProgress(Constants.maxProgressValue, duration: Constants.progressDuration)
        default:
            break
        }
    }

    /// Observes errors during the update process.
    ///
    /// - Parameters:
    ///     - event: event during the update
    func listenErrorEvents(_ event: RemoteUpdateEvent?) {
        switch event {
        case .downloadFailed, .updateFailed:
            isUpdateFinished = false
            viewModel?.cancelUpdateProcess()
            updateButtonView()
            if event == .downloadFailed {
                downloadingStepView?.model.state = .error
            } else {
                sendingStepView?.model.state = .error
            }
        default:
            break
        }
    }

    /// Manage update progress.
    ///
    /// - Parameters:
    ///     - progress: current progress
    func updateProgress(progress: Int?) {
        let progress = progress ?? 0
        var currentProgress: Int = 0
        if isFirmwareAlreadyDownloaded {
            currentProgress = progress/Constants.twoSteps
        } else {
            if isDownloadOnly {
                currentProgress = progress
            } else if viewModel?.state.value.deviceUpdateStep.value == .downloadStarted {
                currentProgress = progress/Constants.threeSteps
            } else {
                currentProgress = (progress + Constants.maxProgressValue)/Constants.threeSteps
            }
        }
        progressView.setProgress(currentProgress, animationDuration: Constants.progressDuration)
    }

    /// Updates button view.
    func updateButtonView() {
        continueButton.setTitle(isUpdateFinished
                                    ? L10n.commonContinue
                                    : L10n.commonRetry,
                                for: .normal)
        continueButton.setTitleColor(isUpdateFinished ? .white : ColorName.defaultTextColor.color, for: .normal)
        continueButton.cornerRadiusedWith(backgroundColor: isUpdateFinished ? ColorName.highlightColor.color : ColorName.whiteAlbescent.color,
                                          borderColor: .clear,
                                          radius: Style.largeCornerRadius)
        continueButton.isHidden = false
    }

    /// Presents an alert when internet is not available.
    func showConnectionUnreachableAlert() {
        let validateAction = AlertAction(title: L10n.commonRetry, actionHandler: { [weak self] in
            self?.progressView.resetProgress()
            self?.viewModel?.startNetworkReachability()
            self?.viewModel?.startUpdateProcess()
        })
        let cancelAction = AlertAction(title: L10n.cancel, actionHandler: { [weak self] in
            self?.coordinator?.back()
        })

        self.showAlert(title: L10n.deviceUpdateConnectionInterruptedTitle,
                       message: L10n.deviceUpdateConnectionInterruptedDescription,
                       cancelAction: cancelAction,
                       validateAction: validateAction)
    }

    /// Shows an alert view when update has been cancelled while entering background or disconnecting.
    func showUpdateCancelledAlert() {
        guard !isUpdateCancelledAlertShown else {
            return
        }

        isUpdateCancelledAlertShown = true
        let validateAction = AlertAction(
            title: L10n.ok,
            actionHandler: { [weak self] in
                self?.coordinator?.back()
            })
        let alert = AlertViewController.instantiate(
            title: L10n.firmwareAndMissionUpdateCancelledTitle,
            message: L10n.firmwareAndMissionUpdateCancelledControllerMessage,
            validateAction: validateAction)
        present(alert, animated: true, completion: nil)
    }

    /// Init the ViewModel for remote update.
    func initViewModel() {
        viewModel = RemoteUpdateViewModel()
        isDownloadOnly = viewModel?.needDownload() == true
            && viewModel?.state.value.remoteControlConnectionState?.isConnected() == false
        isFirmwareAlreadyDownloaded = viewModel?.needDownload() == false

        let version = viewModel?.state.value.idealFirmwareVersion ?? ""
        downloadingStepView.model = UpdateStepModel(state: .todo,
                                                    title: L10n.firmwareMissionUpdateDownloadingFirmware(version))
        sendingStepView.model = UpdateStepModel(state: .todo,
                                                title: L10n.firmwareMissionUpdateSendingToRemoteControl(version))
        rebootingStepView.model = UpdateStepModel(state: .todo, title: L10n.firmwareMissionUpdateRebootAndUpdate)

        viewModel?.state.valueChanged = { [weak self] state in
            self?.updateDeviceUpdateState(state)
        }
        viewModel?.state.value.deviceUpdateStep.valueChanged = { [weak self] step in
            self?.updateStepView(step)
        }

        // Check if we can start the update.
        if viewModel?.canStartUpdate() == true {
            viewModel?.startUpdateProcess()
            // In case of download only.
            if isDownloadOnly {
                progressView.displayDownloadOnly()
                sendingStepView.isHidden = true
                rebootingStepView.isHidden = true
            } else if isFirmwareAlreadyDownloaded {
                downloadingStepView.isHidden = true
            }
        } else {
            coordinator?.back()
        }
    }

    /// Updates current update state.
    ///
    /// - Parameters:
    ///     - state: state of the update
    func updateDeviceUpdateState(_ state: RemoteUpdateState) {
        if state.remoteControlConnectionState?.isConnected() == false
            && state.deviceUpdateStep.value == .uploading {
            showUpdateCancelledAlert()
        }
        if !isFirmwareAlreadyDownloaded,
           state.isNetworkReachable == false {
            // Display connection error alerts.
            showConnectionUnreachableAlert()
        }

        updateProgressView(step: state.deviceUpdateStep.value,
                           progress: state.currentProgress)
        listenErrorEvents(state.deviceUpdateEvent)
    }

    /// Called when the app enters background.
    @objc func didEnterBackground() {
        if viewModel?.state.value.deviceUpdateStep.value.canCancelProcess == true {
            viewModel?.cancelUpdateProcess()
            showUpdateCancelledAlert()
        } else if viewModel?.state.value.deviceUpdateStep.value == .processing {
            // Update is cancelled is this case because connection with remote is lost when app enters background
            showUpdateCancelledAlert()
        } else {
            coordinator?.back()
        }
    }
}
