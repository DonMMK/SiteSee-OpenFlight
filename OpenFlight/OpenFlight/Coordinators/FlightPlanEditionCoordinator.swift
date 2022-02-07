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

// MARK: - Protocols
/// Delegate that gets notified when an overcontext modal is dismissed.
protocol OverContextModalDelegate: AnyObject {
    /// Called when modal will get dismissed.
    func willDismissModal()
}

/// Coordinator for Flight Plan edition.
public final class FlightPlanEditionCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?

    // MARK: - Private Properties
    private weak var overContextModalDelegate: OverContextModalDelegate?
    private let topBarHiderIdentifier = "FlightPlanEditionCoordinator"

    // MARK: - Public Funcs
    public func start() {
        assert(false) // Forbidden start
    }

    /// Starts the coordinator.
    ///
    /// - Parameters:
    ///    - panelCoordinator: panel coordinator
    ///    - mapViewController: controller for the map
    ///    - mapViewRestorer: restorer for the map
    ///
    /// Note: these parameters are needed because, when entering
    /// Flight Plan edition, map view is transferred to the new
    /// view controller. Map is restored back to its original
    /// container afterwards with `MapViewRestorer` protocol.
    func start(panelCoordinator: FlightPlanPanelCoordinator,
               mapViewController: MapViewController,
               mapViewRestorer: MapViewRestorer) {
        let viewController = mapViewController
            .editionProvider(coordinator: self,
                             panelCoordinator: panelCoordinator,
                             flightPlanServices: Services.hub.flightPlan,
                             mapViewRestorer: mapViewRestorer)
        Services.hub.ui.hudTopBarService.forbidTopBarDisplay(hiderIdentifier: topBarHiderIdentifier)
        self.navigationController = NavigationController(rootViewController: viewController)
        self.navigationController?.isNavigationBarHidden = true
        self.overContextModalDelegate = viewController
    }

    /// Dismisses flight plan edition view.
    func dismissFlightPlanEdition() {
        Services.hub.ui.hudTopBarService.allowTopBarDisplay(hiderIdentifier: topBarHiderIdentifier)
        self.parentCoordinator?.dismissChildCoordinator(animated: false)
    }
}

// MARK: - HistoryMediasActionDelegate
extension FlightPlanEditionCoordinator: HistoryMediasAction {
    func handleHistoryCellAction(with flightModel: FlightPlanModel, actionType: HistoryMediasActionType) {
        guard let strongParentCoordinator = self.parentCoordinator as? HUDCoordinator else { return }

        self.parentCoordinator?.dismissChildCoordinator {
            strongParentCoordinator.handleHistoryCellAction(with: flightModel,
                                                            actionType: actionType)
        }
    }
}
