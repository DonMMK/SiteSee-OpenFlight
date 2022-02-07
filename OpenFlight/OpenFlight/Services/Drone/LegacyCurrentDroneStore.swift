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

import GroundSdk
import Combine

/// Legacy class that performs side-effects on drone connection
public final class LegacyCurrentDroneStore {
    // MARK: - Internal Enums
    enum NotificationKeys {
        static let flightPlanRunningNotificationKey: String = "flightPlanRunningNotificationKey"
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var stateRef: Ref<DeviceState>?
    private var mediaMetadataRef: Ref<Camera2MediaMetadata>?
    private var isFlightPlanAlreadyShown: Bool = false
    private unowned var currentMissionManager: CurrentMissionManager

    // MARK: - Init
    public init(droneHolder: CurrentDroneHolder, currentMissionManager: CurrentMissionManager) {
        self.currentMissionManager = currentMissionManager
        droneHolder.dronePublisher.sink { [unowned self] drone in
            listenState(drone)
        }
        .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
private extension LegacyCurrentDroneStore {
    /// Listens drone state.
    func listenState(_ drone: Drone) {
        stateRef = drone.getState { [weak self] state in
            guard state?.connectionState == .connected else { return }
            self?.updateDroneState(drone)
        }
    }

    /// Updates drone state.
    func updateDroneState(_ drone: Drone) {
        // Enable streaming by default.
        if !drone.isUpdating {
            drone.getPeripheral(Peripherals.streamServer)?.enabled = true
        }

        if let flightCameraRecorder = drone.getPeripheral(Peripherals.flightCameraRecorder) {
            flightCameraRecorder.activePipelines.value = flightCameraRecorder.activePipelines.supportedValues
        }
    }
}
