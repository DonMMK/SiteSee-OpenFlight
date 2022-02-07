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

import SafariServices
import SwiftyUserDefaults

/// Coordinator for Dashboard part.
open class DashboardCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?
    /// The services. Warning: only here for availability in extensions, don't use from the outside
    public unowned var services: ServiceHub

    // MARK: - Init
    public init(services: ServiceHub) {
        self.services = services
    }

    // MARK: - Public Funcs
    public func start() {
        let dashboardViewModel = DashboardViewModel(service: services.ui.variableAssetsService,
                                                    projectManager: services.flightPlan.projectManager,
                                                    cloudSynchroWatcher: services.cloudSynchroWatcher,
                                                    projectManagerUiProvider: services.ui.projectManagerUiProvider)
        let viewController = DashboardViewController.instantiate(coordinator: self, viewModel: dashboardViewModel)
        // Prevents not fullscreen presentation style since iOS 13.
        viewController.modalPresentationStyle = .fullScreen
        self.navigationController = NavigationController(rootViewController: viewController)
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.modalPresentationStyle = .fullScreen
    }

    open func startPhotogrammetryDebug() {

    }

}

// MARK: - Dashboard Navigation
extension DashboardCoordinator: DashboardCoordinatorNavigation {
    /// Starts Parrot Debug screen.
    func startParrotDebug() {
        let debugCoordinator = ParrotDebugCoordinator()
        debugCoordinator.parentCoordinator = self
        debugCoordinator.start()
        self.present(childCoordinator: debugCoordinator)
    }

    /// Starts Drone infos.
    func startDroneInfos() {
        let droneCoordinator = DroneCoordinator(services: services)
        droneCoordinator.parentCoordinator = self
        droneCoordinator.start()
        self.present(childCoordinator: droneCoordinator)
    }

    /// Starts Remote details screen.
    func startRemoteInfos() {
        let remoteCoordinator = RemoteCoordinator()
        remoteCoordinator.parentCoordinator = self
        remoteCoordinator.start()
        self.present(childCoordinator: remoteCoordinator)
    }

    /// Starts device update screens.
    ///
    /// - Parameters:
    ///     - model: device model
    func startUpdate(model: DeviceUpdateModel) {
        switch model {
        case .drone:
            let updateCoordinator = DroneFirmwaresCoordinator()
            updateCoordinator.parentCoordinator = self
            updateCoordinator.start()
            self.present(childCoordinator: updateCoordinator, overFullScreen: true)
        case .remote:
            let viewController = RemoteUpdateViewController.instantiate(coordinator: self)
            self.push(viewController)
        }
    }

    /// Starts Medias gallery.
    func startMedias() {
        let galleryCoordinator = GalleryCoordinator()
        galleryCoordinator.parentCoordinator = self
        galleryCoordinator.start()
        self.present(childCoordinator: galleryCoordinator)
    }

    /// Starts settings
    func startSettings() {
        let settingsCoordinator = SettingsCoordinator()
        settingsCoordinator.parentCoordinator = self
        settingsCoordinator.start()
        self.present(childCoordinator: settingsCoordinator)
    }

    /// Starts my flights.
    ///
    /// - Parameters:
    ///     - viewModel: MyFlights view model
    func startMyFlights() {
        let viewController = MyFlightsViewController.instantiate(coordinator: self)
        self.push(viewController)
    }

    /// Starts project manager.
    func startProjectManager() {
        let viewModel = ProjectManagerViewModel(coordinator: self,
                                                manager: services.flightPlan.projectManager,
                                                cloudSynchroWatcher: services.cloudSynchroWatcher,
                                                projectManagerUiProvider: services.ui.projectManagerUiProvider)

        let viewController = ProjectManagerViewController.instantiate(coordinator: self,
                                                                      viewModel: viewModel)
        push(viewController)
    }

    /// Starts flights details.
    public func startFlightExecutionDetails(_ execution: FlightPlanModel) {
        let viewModel = FlightDetailsViewController.ViewModel
            .execution(FlightPlanExecutionViewModel(
                        flightPlan: execution,
                        flightRepository: services.repos.flight,
                        coordinator: self,
                        flightPlanExecutionDetailsSettingsProvider: Services.hub.ui.flightPlanExecutionDetailsSettingsProvider,
                        flightPlanUiStateProvider: services.ui.flightPlanUiStateProvider))
        let viewController = FlightDetailsViewController.instantiate(viewModel: viewModel)
        self.push(viewController)
    }

    /// Starts flights details.
    func startFlightDetails(flight: FlightModel) {
        let viewModel = FlightDetailsViewModel(service: services.flight.service,
                                               flight: flight,
                                               flightPlanTypeStore: services.flightPlan.typeStore,
                                               coordinator: self)
        let viewController = FlightDetailsViewController.instantiate(viewModel: .details(viewModel))
        self.push(viewController)
    }

    /// Show delete flight confirmation popup.
    ///
    /// - Parameters:
    ///     - didTapDelete: completion block called when user tap on delete button.
    func showDeleteFlightPopupConfirmation(didTapDelete: @escaping () -> Void) {
         let deleteAction = AlertAction(title: L10n.commonDelete,
                                        style: .destructive,
                                        actionHandler: { didTapDelete() })
         let cancelAction = AlertAction(title: L10n.cancel,
                                        style: .cancel,
                                        actionHandler: {})
         let alert = AlertViewController.instantiate(title: L10n.alertDeleteFlightLogTitle,
                                                     message: L10n.alertDeleteFlightLogMessage,
                                                     cancelAction: cancelAction,
                                                     validateAction: deleteAction)
         presentModal(viewController: alert)
     }

    /// Show delete project confirmation popup.
    ///
    /// - Parameters:
    ///     - didTapDelete: completion block called when user tap on delete button.
    func showDeleteProjectPopupConfirmation(didTapDelete: @escaping () -> Void) {
         let deleteAction = AlertAction(title: L10n.commonDelete,
                                        style: .destructive,
                                        actionHandler: { didTapDelete() })
         let cancelAction = AlertAction(title: L10n.cancel,
                                        style: .cancel,
                                        actionHandler: {})
         let alert = AlertViewController.instantiate(title: L10n.alertDeleteProjectTitle,
                                                     message: L10n.alertDeleteProjectMessage,
                                                     cancelAction: cancelAction,
                                                     validateAction: deleteAction)
         presentModal(viewController: alert)
     }

    /// Displays my acount screen.
    func startMyAccount() {
        let viewController = DashboardMyAccountViewController.instantiate(coordinator: self)
        push(viewController)
    }

    /// Starts Confidentiality screen.
    func startConfidentiality() {
        guard let currentAccount = AccountManager.shared.currentAccount,
              let loginCoordinator = currentAccount.destinationCoordinator else {
            return
        }

        // If you need to show a data confidentiality view (ie: GPDR), start data confidentiality from login coordinator here.
        loginCoordinator.parentCoordinator = self
        currentAccount.startDataConfidentiality()
        self.present(childCoordinator: loginCoordinator, animated: true, completion: nil)
    }

    /// Starts map preloading.
    func startMapPreloading() {
    }

    /// Dismisses the dashboard.
    ///
    /// - Parameters:
    ///     - completion: completion when dismiss is completed
    func dismissDashboard(completion: (() -> Void)? = nil) {
        self.dismissCoordinatorWithAnimation(animationDirection: .fromRight, completion: completion)
    }

    /// Function used to handle navigation after clicking on MyFlightsAccountView.
    func startMyFlightsAccountView() {
        guard let currentAccount = AccountManager.shared.currentAccount,
              let loginCoordinator = currentAccount.destinationCoordinator else {
            return
        }

        loginCoordinator.parentCoordinator = self
        currentAccount.startMyFlightsAccountView()
        self.present(childCoordinator: loginCoordinator)
    }
}

extension DashboardCoordinator {

    /// Opens a Project/Flight Plan vue.
    ///
    /// - Parameters:
    ///     - project: a flightPlan project
    func open(project: ProjectModel) {
        dismissDashboard {
            self.services.flightPlan.projectManager.loadEverythingAndOpen(project: project)
        }
    }
}

extension DashboardCoordinator: ExecutionsListDelegate {
    /// Starts Flight Plan.
    ///
    /// - Parameters:
    ///     - flightPlan: Flight Plan
    public func open(flightPlan: FlightPlanModel) {
        dismissDashboard {
            self.services.flightPlan.projectManager.loadEverythingAndOpen(flightPlan: flightPlan)
        }
    }

    public func backDisplay() {
        self.back()
    }

    public func handleHistoryCellAction(with: FlightPlanModel, actionType: HistoryMediasActionType?) {

    }
}
