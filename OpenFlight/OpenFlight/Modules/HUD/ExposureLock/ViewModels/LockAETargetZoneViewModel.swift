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

import Combine
import GroundSdk

/// ViewModel for LockAE Target zone.
final class LockAETargetZoneViewModel {

    // MARK: - Internal Published Properties
    /// Current exposure lock state publisher.
    var statePublisher: AnyPublisher<ExposureLockState, Never> {
        exposureLockService.statePublisher
    }
    /// Current exposure lock region publisher.
    var lockRegionPublisher: AnyPublisher<ExposureLockRegion?, Never> {
        exposureLockService.lockRegionPublisher
    }
    /// Current exposure lock state value..
    var stateValue: ExposureLockState {
        exposureLockService.stateValue
    }
    /// Current exposure lock region value.
    var lockRegionValue: ExposureLockRegion? {
        exposureLockService.lockRegionValue
    }
    /// Whether tap events must be ignored.
    var tapEventsIgnored: Bool {
        return exposureLockService.stateValue == .unavailable
            || exposureLockService.stateValue.locking
            || manualMode
    }

    // MARK: - Private Properties
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// Camera exposure service.
    private unowned var exposureService: ExposureService
    /// Camera exposure lock service.
    private unowned var exposureLockService: ExposureLockService
    /// Whether exposure mode is manual.
    private var manualMode = false

    /// Constructor.
    ///
    /// - Parameters:
    ///   - exposureService: exposure service
    ///   - exposureLockService: exposure lock service
    init(exposureService: ExposureService, exposureLockService: ExposureLockService) {
        self.exposureService = exposureService
        self.exposureLockService = exposureLockService

        exposureService.modePublisher
            .sink { [unowned self] mode in
                manualMode = mode == .manual
            }
            .store(in: &cancellables)
    }

    /// Unlocks exposure.
    func unlock() {
        exposureLockService.unlock()
    }

    /// Locks exposure on region according to selection values in stream screen.
    ///
    /// - Parameters:
    ///   - centerX: horizontal position in the video (relative position, from left (0.0) to right (1.0))
    ///   - centerY: vertical position in the video (relative position, from bottom (0.0) to top (1.0))
    func lockOnRegion(centerX: Double, centerY: Double) {
        exposureLockService.lockOnRegion(centerX: centerX, centerY: centerY)
    }
}
