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

import UIKit
import Combine

/// Main view controller for the Heads-Up Display (HUD).
final public class HUDViewController: UIViewController, DelayedTaskProvider {
    // MARK: - Internal Outlets
    @IBOutlet internal weak var splitControls: SplitControls!
    @IBOutlet internal weak var missionControls: MissionControls!
    @IBOutlet internal weak var rightPanelContainerControls: RightPanelContainerControls!
    @IBOutlet internal weak var videoControls: VideoControls!
    @IBOutlet internal weak var alertControls: AlertControls!

    // MARK: - Private Outlets
    @IBOutlet private weak var joysticksView: JoysticksView!
    @IBOutlet private weak var alertPanelContainerView: UIView!
    @IBOutlet private weak var customValidationView: UIView!
    @IBOutlet private weak var AELockContainerView: UIView!
    @IBOutlet private weak var indicatorContainerView: UIView!
    @IBOutlet private weak var topStackView: UIStackView!
    @IBOutlet private weak var dismissMissionLauncherButton: UIButton!

    // MARK: - Public Properties
    var customControls: CustomHUDControls?

    // MARK: - Internal Properties
    public weak var coordinator: HUDCoordinator?
    var delayedTaskComponents: DelayedTaskComponents = DelayedTaskComponents()

    // MARK: - Private Properties
    // TODO: wrong injection
    private unowned var currentMissionManager = Services.hub.currentMissionManager
    private unowned var protobufMissionsManager = Services.hub.drone.protobufMissionsManager
    private unowned var topBarService = Services.hub.ui.hudTopBarService

    private var cancellables = Set<AnyCancellable>()
    private var defaultMapViewController: MapViewController?

    /// View models.
    private let joysticksViewModel = JoysticksViewModel()
    private let remoteShutdownAlertViewModel = RemoteShutdownAlertViewModel()
    private lazy var helloWorldViewModel: HelloWorldMissionViewModel? = {
        // Prevent from useless helloWorld init if mission is not loaded.
        let missionsToLoad = protobufMissionsManager.getMissionToLoadAtStart()
        let helloMissionId = HelloWorldMissionSignature().missionUID
        guard missionsToLoad.contains(where: { $0.missionUID == helloMissionId }) else { return nil }

        return HelloWorldMissionViewModel()
    }()
    private let landingViewModel = HUDLandingViewModel()
    /// Cellular indicator view model. Used to display indicator in the center of the HUD.
    private let cellularIndicatorViewModel = HUDCellularIndicatorViewModel()
    /// View model which tells if 4G pairing is available.
    private let cellularPairingAvailabilityViewModel = CellularPairingAvailabilityViewModel()
    /// Manages entire 4G pairing process.
    private let cellularPairingProcessViewModel = CellularPairingProcessViewModel()

    /// Property used to store the alert panel view controller.
    private var currentAlertPanelVC: AlertPanelViewController?

    // MARK: - Private Enums
    private enum Constants {
        static let indicatorDelay: Double = 2.0
        static let cellularIndicatorTaskKey: String = "cellularIndicatorTaskKey"
        static let orientationKeyWord: String = "orientation"
    }

    // MARK: - Setup
    static func instantiate(coordinator: HUDCoordinator) -> HUDViewController {
        let viewController = StoryboardScene.Hud.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()
        listenWillEnterForeground()
        splitControls.start()
        customControls = CustomHUDControlsProvider.shared.customControls
        customControls?.start()
        setupAlertPanel()

        listenMissionMode()
        listenTopBarChanges()
        listenRemoteShutdownAlert()
        listenPairingProcessViewModel()
        listenMissionLauncherState()

        // Handle rotation when coming from Onboarding.
        let value = UIInterfaceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(value, forKey: Constants.orientationKeyWord)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        splitControls.setupSplitIfNeeded()
        splitControls.displayMapOr3DasChild()
        // Show flight plan panel if needed.
        if currentMissionManager.mode.isRightPanelRequired {
            rightPanelContainerControls.viewModel.forceHidePanel(false)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.hud,
                             logType: .screen)
        rightPanelContainerControls.start()
        updateViewModels()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        rightPanelContainerControls.stop()
        removeViewModelObservers()
        stopTasksIfNeeded()
        removeContainerViews()
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    public override var shouldAutorotate: Bool {
        return true
    }

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let topBar = segue.destination as? HUDTopBarViewController {
            topBar.navigationDelegate = self
        } else if let cameraStreamingVC = segue.destination as? HUDCameraStreamingViewController {
            splitControls.cameraStreamingViewController = cameraStreamingVC
            cameraStreamingVC.delegate = self
        } else if let indicatorViewController = segue.destination as? HUDIndicatorViewController {
            splitControls.delegate = indicatorViewController
            indicatorViewController.indicatorViewControllerNavigation = self
        } else if let bottomBarContainerVC = segue.destination as? BottomBarContainerViewController {
            bottomBarContainerVC.coordinator = coordinator
        } else if let missionLauncherVC = segue.destination as? MissionProviderSelectorViewController {
            // TODO: wrong injection. Also... SEGUES
            let services: ServiceHub = Services.hub
            missionLauncherVC.viewModel = MissionProviderSelectorViewModel(currentMissionManager: services.currentMissionManager,
                                                                           missionsStore: services.missionsStore,
                                                                           delegate: self)
        } else if let lockAETargetZoneVC = segue.destination as? LockAETargetZoneViewController {
            videoControls.lockAETargetZoneViewController = lockAETargetZoneVC
        } else if let sliders = segue.destination as? CameraSlidersViewController {
            coordinator?.handleCameraSlidersViewController(sliders)
        }
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    /// Shows the SIM Pin Code if necessary.
    func showCellularPinCodeIfNeeded() {
        if cellularPairingProcessViewModel.isPinCodeRequested {
            coordinator?.displayCellularPinCode()
        }
    }
}

// MARK: - Actions
private extension HUDViewController {
    /// Dismiss mission Launcher by tapping outside it
    @IBAction func dismissMissionLauncherButtonTouchedUpInside() {
        coordinator?.hideMissionLauncher()
    }
}

// MARK: - Private Funcs
private extension HUDViewController {

    func listenWillEnterForeground() {
        guard let splitControls = splitControls else { return }
        NotificationCenter.default.addObserver(splitControls,
                                               selector: #selector(splitControls.updateConstraintForForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    /// Listen for mission mode
    func listenMissionMode() {
        currentMissionManager.modePublisher.sink { [unowned self] in
            setupMap()
            coordinator?.presentModeEntryCoordinatorIfNeeded(mode: $0)
            videoControls.enableAeTarget(enabled: !$0.isTrackingMode)
        }
        .store(in: &cancellables)
    }

    func listenTopBarChanges() {
        topBarService.showTopBarPublisher
            .sink { [unowned self] in
                topStackView.isHidden = !$0
            }
            .store(in: &cancellables)
    }

    /// Listens if modal popup can be shown
    func listenRemoteShutdownAlert() {
        remoteShutdownAlertViewModel.canShowModal
            .removeDuplicates()
            .sink { [weak self] canShowModal in
                if canShowModal {
                    self?.showRemoteShutdownAlert()
                }
            }
            .store(in: &cancellables)
    }

    /// Updates cellular process.
    func listenPairingProcessViewModel() {
        cellularPairingProcessViewModel.$isPinCodeRequested
            .removeDuplicates()
            .combineLatest(cellularPairingProcessViewModel.$pairingStep,
                           cellularPairingProcessViewModel.$pairingError,
                           cellularPairingAvailabilityViewModel.$canShowModal)
            .sink { [unowned self] (pinCodeRequested, pairingProcessStep, pairingProcessError, canShowModal) in
                if pinCodeRequested {
                    coordinator?.displayCellularPinCode()
                } else if canShowModal {
                    // If allowed to auto retry, error is not displayed
                    guard pairingProcessStep == .pairingProcessSuccess else {
                        switch pairingProcessError {
                        case .connectionUnreachable,
                             .unableToConnect,
                             .unauthorizedUser,
                             .serverError:
                            DispatchQueue.main.async { [weak self] in
                                self?.showPairingAlert(error: pairingProcessError)
                            }
                        default:
                            return
                        }

                        return
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Listen for Mission Launcher sate changes
    func listenMissionLauncherState() {
        guard let coordinator = coordinator else { return }
        coordinator.showMissionLauncherPublisher.sink { [unowned self] in
            if $0 {
                dismissMissionLauncherButton.isHidden = false
            } else {
                dismissMissionLauncherButton.isHidden = true
            }
        }
        .store(in: &cancellables)
    }

    /// Map setup.
    func setupMap() {
        let mode = currentMissionManager.mode
        if let map = mode.customMapProvider?() as? MapViewController {
            // Add custom map.
            self.splitControls.addMap(map, parent: self)
            // Force recreate default map next time it will be necessary (this will deinit it).
            defaultMapViewController = nil
        } else {
            // Add default map, create it if needed.
            // defaultMapViewController is used to keep map when mission modes use same default map.
            let map = defaultMapViewController ?? StoryboardScene.Map.initialScene.instantiate()
            defaultMapViewController = map
            map.customControls = customControls
            customControls?.mapViewController = map
            self.splitControls.addMap(map, parent: self)
        }
    }

    /// Sets up left panel for proactive alerts.
    func setupAlertPanel() {
        let currentAlertPanelVC = HUDAlertPanelProvider.shared.alertPanelViewControllers?.alertPanelViewController()
        let alertPanel = currentAlertPanelVC ?? HUDAlertPanelViewController.instantiate()
        alertPanel.delegate = alertControls
        self.addChild(alertPanel)
        alertPanel.view.removeFromSuperview()
        alertPanelContainerView.addWithConstraints(subview: alertPanel.view)
    }

    /// Changes joysticks visibility regarding view model state.
    ///
    /// - Parameters:
    ///     - state: current joysticks visibility state
    func updateJoysticksVisibility(with state: JoysticksState?) {
        joysticksView.isHidden = state?.shouldHideJoysticks == true
    }

    /// Shows remote alert shutdown process.
    func showRemoteShutdownAlert() {
        coordinator?.displayRemoteAlertShutdown()
    }

    /// Updates view models values.
    func updateViewModels() {
        helloWorldViewModel?.state.valueChanged = { [weak self] state in
            self?.showHelloWorldIfNeeded(state: state)
        }
        joysticksViewModel.state.valueChanged = { [weak self] state in
            self?.updateJoysticksVisibility(with: state)
        }
        landingViewModel.state.valueChanged = { [weak self] state in
            self?.updateLandingView(with: state)
        }
        cellularIndicatorViewModel.state.valueChanged = { [weak self] state in
            self?.updateCellularIndicatorView(with: state)
        }
        updateLandingView(with: landingViewModel.state.value)

        if let state = helloWorldViewModel?.state.value {
            showHelloWorldIfNeeded(state: state)
        }

        updateJoysticksVisibility(with: joysticksViewModel.state.value)
        updateCellularIndicatorView(with: cellularIndicatorViewModel.state.value)
        cellularPairingAvailabilityViewModel.updateAvailabilityState()
    }

    /// Removes each view model value changed.
    func removeViewModelObservers() {
        joysticksViewModel.state.valueChanged = nil
        helloWorldViewModel?.state.valueChanged = nil
        landingViewModel.state.valueChanged = nil
        cellularIndicatorViewModel.state.valueChanged = nil
    }

    /// Removes container views.
    func removeContainerViews() {
        indicatorContainerView.removeSubViews()
    }

    /// Stops current tasks if its needed.
    func stopTasksIfNeeded() {
        if isTaskPending(key: Constants.cellularIndicatorTaskKey) {
            cancelDelayedTask(key: Constants.cellularIndicatorTaskKey)
        }
    }
}

// MARK: - Utils for Hello World Mission
private extension HUDViewController {
    /// Display a view when the drone sends a Hello World protobuf message.
    ///
    /// - Parameters:
    ///     - state: The state of the Hello World Protobuf mission
    func showHelloWorldIfNeeded(state: HelloWorldMissionState) {
        guard state.missionState == .active,
              let messageToDisplay = helloWorldViewModel?.messageToDisplay(),
              !HelloWorldMessageView.isAlreadyDisplayed(in: self) else {
            return
        }

        let helloWorldMessageView = HelloWorldMessageView()
        helloWorldMessageView.displayThenHide(in: self, with: messageToDisplay)
    }
}

// MARK: - Cellular Landing Indicator Views
private extension HUDViewController {
    /// Updates cellular indicator view or display error.
    ///
    /// - Parameters:
    ///     - state: The cellular indicator state
    func updateCellularIndicatorView(with state: HUDCellularIndicatorState?) {
        guard let state = state else { return }

        if state.shouldShowCellularAlert {
            switch state.currentAlert {
            case .simLocked:
                coordinator?.displayCellularPinCode()
            case .airplaneMode,
                 .networkStatusDenied,
                 .networkStatusError,
                 .notRegistered,
                 .simBlocked:
                displayCellularAlert(with: state)
            default:
                break
            }
        } else if state.shouldShowCellularInfo {
            guard !landingViewModel.state.value.isLandingOrRth else { return }

            displayCellularIndicatorView(with: state)
        }
    }

    /// Updates the indicator view according to the landing state.
    ///
    /// - Parameters:
    ///     - state: current information about landing or return home state
    func updateLandingView(with state: HUDLandingState) {
        guard landingViewModel.state.value.isLandingOrRth else { return }

        addIndicatorView(with: HUDLandingView())
    }

    /// Displays a cellular alert.
    ///
    /// - Parameters:
    ///     - state: The cellular indicator state
    func displayCellularAlert(with state: HUDCellularIndicatorState) {
        guard let title = state.currentAlert?.title,
              let description = state.currentAlert?.description else {
            return
        }

        let resumeAction = AlertAction(title: L10n.commonRetry, actionHandler: { [weak self] in
            self?.cellularIndicatorViewModel.resumeProcess()
        })

        let cancelAction = AlertAction(title: L10n.cancel,
                                       cancelCustomColor: ColorName.white20,
                                       actionHandler: { [weak self] in
                                        self?.cellularIndicatorViewModel.stopProcess()
                                       })

        let alert = AlertViewController.instantiate(title: title,
                                                    message: description,
                                                    messageColor: .redTorch,
                                                    closeButtonStyle: .cross,
                                                    cancelAction: cancelAction,
                                                    validateAction: resumeAction)

        self.present(alert, animated: true)
    }

    /// Adds a cellular indicator view.
    ///
    /// - Parameters:
    ///     - state: The cellular indicator state
    func displayCellularIndicatorView(with state: HUDCellularIndicatorState) {
        let view = HUDCellularIndicatorView()
        view.configure(state: state.currentCellularState)
        addIndicatorView(with: view)
        setupDelayedTask(addCellularAnimation,
                         delay: Constants.indicatorDelay,
                         key: Constants.cellularIndicatorTaskKey)
    }

    /// Adds the cellular animation.
    func addCellularAnimation() {
        UIView.animate(withDuration: Style.longAnimationDuration,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: {
                        self.indicatorContainerView.alpha = 0.0
                       }, completion: { (_) in
                        self.indicatorContainerView.isHidden = true
                        self.indicatorContainerView.alpha = 1.0
                        self.cellularIndicatorViewModel.stopProcess()
                       })
    }

    /// Adds indicator view.
    ///
    /// - Parameters:
    ///     - view: view to add
    func addIndicatorView(with view: UIView) {
        indicatorContainerView.isHidden = false
        indicatorContainerView.removeSubViews()
        indicatorContainerView.addWithConstraints(subview: view)
    }
}

// MARK: - Cellular Pairing Process
private extension HUDViewController {

    /// Shows an alert when pairing process fails.
    ///
    /// - Parameters:
    ///     - error: error of the alert
    func showPairingAlert(error: PairingProcessError?) {
        let validateAction = AlertAction(title: L10n.commonRetry, actionHandler: { [weak self] in
            self?.cellularPairingProcessViewModel.retryPairingProcess()
        })
        let cancelAction = AlertAction(title: L10n.cancel,
                                       cancelCustomColor: .white20,
                                       actionHandler: { [weak self] in
                                        self?.coordinator?.dismiss()
                                       })
        let alert = AlertViewController.instantiate(title: L10n.cellularConnectionFailedToConnect,
                                                    message: error?.alertMessage ?? L10n.cellularConnectionServerError,
                                                    messageColor: .redTorch,
                                                    closeButtonStyle: .cross,
                                                    cancelAction: cancelAction,
                                                    validateAction: validateAction)
        self.present(alert, animated: true)
    }
}

extension HUDViewController: MissionProviderSelectorViewModelDelegate {
    func userDidTapAnyMission() {
        coordinator?.hideMissionLauncher()
    }
}
