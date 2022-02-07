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
import GroundSdk
import Reachability

/// State for `RemoteUpdateViewModel`.
final class RemoteUpdateState: DevicesConnectionState {
    // MARK: - Internal Properties
    var isNetworkReachable: Bool?
    var idealFirmwareVersion: String?
    var deviceUpdateStep: Observable<RemoteUpdateStep> = Observable(RemoteUpdateStep.none)
    var deviceUpdateEvent: RemoteUpdateEvent?
    var currentProgress: Int?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - droneConnectionState: connection state of the drone
    ///     - remoteConnectionState: connection state of the remote
    ///     - isNetworkReachable: network reachability
    ///     - idealFirmwareVersion: The ideal firmware version
    ///     - deviceUpdateStep: state of the update
    ///     - deviceUpdateEvent: event during the update
    ///     - currentProgress: update progress
    init(droneConnectionState: DeviceConnectionState?,
         remoteControlConnectionState: DeviceConnectionState?,
         isNetworkReachable: Bool?,
         idealFirmwareVersion: String?,
         deviceUpdateStep: Observable<RemoteUpdateStep>,
         deviceUpdateEvent: RemoteUpdateEvent?,
         currentProgress: Int?) {
        super.init(droneConnectionState: droneConnectionState, remoteControlConnectionState: remoteControlConnectionState)
        self.isNetworkReachable = isNetworkReachable
        self.idealFirmwareVersion = idealFirmwareVersion
        self.deviceUpdateStep = deviceUpdateStep
        self.deviceUpdateEvent = deviceUpdateEvent
        self.currentProgress = currentProgress
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DevicesConnectionState) -> Bool {
        guard let other = other as? RemoteUpdateState else {
            return false
        }
        return super.isEqual(to: other)
            && self.isNetworkReachable == other.isNetworkReachable
            && self.idealFirmwareVersion == other.idealFirmwareVersion
            && self.deviceUpdateStep.value == other.deviceUpdateStep.value
            && self.deviceUpdateEvent == other.deviceUpdateEvent
            && self.currentProgress == other.currentProgress
    }

    override func copy() -> RemoteUpdateState {
        let copy = RemoteUpdateState(droneConnectionState: self.droneConnectionState,
                                     remoteControlConnectionState: self.remoteControlConnectionState,
                                     isNetworkReachable: self.isNetworkReachable,
                                     idealFirmwareVersion: self.idealFirmwareVersion,
                                     deviceUpdateStep: self.deviceUpdateStep,
                                     deviceUpdateEvent: self.deviceUpdateEvent,
                                     currentProgress: self.currentProgress)
        return copy
    }
}

/// View Model for remote update process.
final class RemoteUpdateViewModel: DevicesStateViewModel<RemoteUpdateState> {
    // MARK: - Private Properties
    private var remoteControlUpdaterRef: Ref<Updater>?
    private var reachability: Reachability?

    // MARK: - Init
    /// Init.
    override init() {
        super.init()

        RemoteControlGrabManager.shared.disableRemoteControl()
    }

    // MARK: - Deinit
    deinit {
        reachability?.stopNotifier()
        RemoteControlGrabManager.shared.enableRemoteControl()
    }

    // MARK: - Override Funcs
    override func listenRemoteControl(remoteControl: RemoteControl) {
        super.listenRemoteControl(remoteControl: remoteControl)

        listenUpdater(remoteControl)
        listenReachability()
    }

    // MARK: - Internal Funcs
    /// Tells whether target firmware needs to be downloaded.
    func needDownload() -> Bool {
        return remoteControlUpdaterRef?.value?.downloadableFirmwares.isEmpty == false
    }

    /// Returns true if the user can start an update.
    func canStartUpdate() -> Bool {
        // Battery level.
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        return updater?.updateUnavailabilityReasons.contains(.notEnoughBattery) == false
    }

    /// Starts download or update process.
    func startUpdateProcess() {
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        if updater?.downloadableFirmwares.isEmpty == false {
            startDownload()
        } else if updater?.applicableFirmwares.isEmpty == false {
            startUpdate()
        }
    }

    /// Cancels the download or the update.
    func cancelUpdateProcess() {
        let updater = remoteControl?.getPeripheral(Peripherals.updater)
        let copy = state.value.copy()

        switch copy.deviceUpdateStep.value {
        case .downloadStarted:
            updater?.cancelDownload()
        case .downloadCompleted, .updateStarted, .uploading, .processing:
            updater?.cancelUpdate()
        default:
            break
        }
    }

    /// Checks if the network is reachable.
    func startNetworkReachability() {
        // Set a default state to nil when we start listen reachability.
        let copy = state.value.copy()
        copy.isNetworkReachable = nil
        self.state.set(copy)
        reachability?.stopNotifier()
        listenReachability()
    }
}

// MARK: - Private Funcs
private extension RemoteUpdateViewModel {
    /// Starts watcher for remote updater.
    ///
    /// - Parameters:
    ///     - remoteControl: current remote
    func listenUpdater(_ remoteControl: RemoteControl) {
        remoteControlUpdaterRef = remoteControl.getPeripheral(Peripherals.updater) { [weak self] updater in
            guard let updater = updater else { return }

            self?.updateFirmwareVersion(updater)
            self?.updateCurrentDownload(updater)
            self?.updateCurrentUpdate(updater)
        }
    }

    /// Updates ideal firmware version.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func updateFirmwareVersion(_ updater: Updater) {
        let copy = self.state.value.copy()
        copy.idealFirmwareVersion = updater.idealVersion?.description
        self.state.set(copy)
    }

    /// Updates current download state.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func updateCurrentDownload(_ updater: Updater) {
        guard let currentDownload = updater.currentDownload else { return }
        ULog.d(.remoteUpdateTag, "Current download: \(currentDownload)")

        let copy = state.value.copy()
        switch currentDownload.state {
        case .downloading:
            copy.deviceUpdateStep.set(.downloadStarted)
        case .canceled:
            copy.deviceUpdateEvent = .downloadCanceled
        case .failed:
            copy.deviceUpdateEvent = .updateFailed
        case .success:
            copy.deviceUpdateStep.set(.downloadCompleted)
        }

        copy.currentProgress = currentDownload.currentProgress
        state.set(copy)
    }

    /// Updates current update state.
    ///
    /// - Parameters:
    ///     - updater: current updater
    func updateCurrentUpdate(_ updater: Updater) {
        guard let currentUpdate = updater.currentUpdate else { return }
        ULog.d(.remoteUpdateTag, "Current update: \(currentUpdate)")

        let copy = state.value.copy()
        switch currentUpdate.state {
        case .processing:
            copy.deviceUpdateStep.set(.processing)
        case .uploading:
            copy.deviceUpdateStep.set(.uploading)
        case .failed:
            copy.deviceUpdateEvent = .updateFailed
        case .canceled:
            copy.deviceUpdateEvent = .updateCanceled
        case .waitingForReboot:
            copy.deviceUpdateStep.set(.rebooting)
        case .success:
            copy.deviceUpdateStep.set(.updateCompleted)
        }

        copy.currentProgress = currentUpdate.currentProgress
        state.set(copy)
    }

    /// Starts watcher for reachability.
    func listenReachability() {
        let copy = state.value.copy()
        do {
            try reachability = Reachability()
            try reachability?.startNotifier()
        } catch {
            copy.isNetworkReachable = false
        }

        reachability?.whenReachable = { _ in
            copy.isNetworkReachable = true
            self.state.set(copy)
        }
        reachability?.whenUnreachable = {  _ in
            copy.isNetworkReachable = false
            self.state.set(copy)
        }
    }

    /// Starts download of the firmware.
    func startDownload() {
        remoteControl?.getPeripheral(Peripherals.updater)?.downloadAllFirmwares()
    }

    /// Starts update of the firmware.
    func startUpdate() {
        remoteControl?.getPeripheral(Peripherals.updater)?.updateToLatestFirmware()
    }
}
