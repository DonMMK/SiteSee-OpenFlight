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

import GroundSdk
import SwiftyUserDefaults

/// State for `PanoramaModeViewModel`.

final class PanoramaModeState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current panorama progress state.
    fileprivate(set) var inProgress: Bool = false
    /// Current panorama progress percentage.
    fileprivate(set) var progress: Int = 0
    /// Current panorama mode.
    fileprivate(set) var mode: PanoramaMode = .vertical
    /// Current panorama mode availability.
    fileprivate(set) var available: Bool = false

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - inProgress: current panorama progress state
    ///    - progress: current panorama progress percentage
    ///    - mode: current panorama mode
    ///    - available: current panorama mode availability
    init(inProgress: Bool,
         progress: Int,
         mode: PanoramaMode,
         available: Bool) {
        self.inProgress = inProgress
        self.progress = progress
        self.mode = mode
        self.available = available
    }

    // MARK: - Internal Funcs
    func isEqual(to other: PanoramaModeState) -> Bool {
        return self.inProgress == other.inProgress
            && self.progress == other.progress
            && self.mode == other.mode
            && self.available == other.available
    }

    /// Returns a copy of the object.
    func copy() -> PanoramaModeState {
        let copy = PanoramaModeState(inProgress: self.inProgress,
                                     progress: self.progress,
                                     mode: self.mode,
                                     available: self.available)
        return copy
    }
}

/// View model that manages panorama mode.

final class PanoramaModeViewModel: DroneWatcherViewModel<PanoramaModeState> {
    // MARK: - Private Properties
    private var animationPilotingItfRef: Ref<AnimationPilotingItf>?
    private var panoramaModeObserver: DefaultsDisposable?
    private var animationItf: AnimationPilotingItf?
    private var isCurrentPanoramaModeAvailable: Bool?

    // MARK: - Init
    override init() {
        super.init()
        animationItf = drone?.getPilotingItf(PilotingItfs.animation)
        isCurrentPanoramaModeAvailable = animationItf?.isPanoramaPhotoCaptureAvailable(PanoramaMode.current) == true
        listenDefault()
    }

    // MARK: - Deinit
    deinit {
        panoramaModeObserver?.dispose()
        panoramaModeObserver = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        listenAnimation(drone: drone)
    }

    // MARK: - Internal Funcs
    /// Starts a panorama photo capture with current mode.
    func startPanoramaPhotoCapture() {
        _ = animationItf?.startAnimation(config: state.value.mode.animationConfig)
    }

    /// Cancels current photo panorama photo capture.
    func cancelPanoramaPhotoCapture() {
        guard let animationItf = animationItf,
            animationItf.isPanoramaPhotoCaptureInProgress
            else {
                return
        }
        _ = animationItf.abortCurrentAnimation()
    }
}

// MARK: - Private Funcs
private extension PanoramaModeViewModel {
    /// Starts watcher for animation piloting interface.
    func listenAnimation(drone: Drone) {
        animationPilotingItfRef = drone.getPilotingItf(PilotingItfs.animation) { [weak self] animationItf in
            self?.animationItf = animationItf
            self?.isCurrentPanoramaModeAvailable = animationItf?.isPanoramaPhotoCaptureAvailable(PanoramaMode.current) == true
            let copy = self?.state.value.copy()
            copy?.inProgress = animationItf?.animation?.status != nil
            copy?.progress = animationItf?.animation?.progress ?? -1
            copy?.available = self?.isCurrentPanoramaModeAvailable == true
            self?.state.set(copy)
        }
    }

    /// Starts watcher for panorama setting default.
    func listenDefault() {
        panoramaModeObserver = Defaults.observe(PanoramaMode.defaultKey, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updatePanoramaMode()
            }
        }
        updatePanoramaMode()
    }

    /// Update current panorama state.
    func updatePanoramaMode() {
        let copy = self.state.value.copy()
        copy.mode = PanoramaMode.current
        copy.available = isCurrentPanoramaModeAvailable ?? false
        self.state.set(copy)
    }
}
