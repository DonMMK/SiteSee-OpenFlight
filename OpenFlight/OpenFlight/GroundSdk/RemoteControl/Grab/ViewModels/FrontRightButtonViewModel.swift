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

import GroundSdk

/// ViewModel which manages takeOff or Land remote control button.
final class FrontRightButtonViewModel: DroneStateViewModel<DeviceConnectionState> {
    // MARK: - Private Properties
    private var criticalAlertViewModel: HUDCriticalAlertViewModel = HUDCriticalAlertViewModel()

    // MARK: - Internal Funcs
    /// Called when front right button is touched up.
    ///
    /// - Parameters:
    ///     - state: sky controller event state
    func frontRightButtonTouchedUp(_ state: SkyCtrl4ButtonEventState) {
        guard state == .pressed else { return }

        performDroneAction()
    }
}

// MARK: - Private Funcs
private extension FrontRightButtonViewModel {
    /// Performs a drone action.
    /// Actions can be TakeOff, Land, HandLand or Hand Launch.
    func performDroneAction() {
        guard let drone = drone else { return }

        if drone.isStateFlying {
            takeOffOrLandDrone()
        } else {
            // Notifies that takeOff is requested.
            NotificationCenter.default.post(name: .takeOffRequestedDidChange,
                                            object: nil,
                                            userInfo: [HUDCriticalAlertConstants.takeOffRequestedNotificationKey: true])
            // Checks is there are no critical alerts.
            guard criticalAlertViewModel.state.value.canTakeOff else { return }

            if drone.isHandLaunchAvailable || drone.isHandLaunchReady {
                drone.startHandLaunch()
            } else {
                takeOffOrLandDrone()
            }
        }
    }

    /// Starts Take Off or Landing action.
    func takeOffOrLandDrone() {
        guard let drone = drone else { return }

        if !drone.isManualPilotingActive {
            // Deactivates RTH if it is the current pilotingItf.
            if drone.getPilotingItf(PilotingItfs.returnHome)?.state == .active {
                _ = drone.getPilotingItf(PilotingItfs.returnHome)?.deactivate()
            } else {
                _ = drone.getPilotingItf(PilotingItfs.manualCopter)?.activate()
            }
        }
        drone.getPilotingItf(PilotingItfs.manualCopter)?.smartTakeOffLand()
    }
}
