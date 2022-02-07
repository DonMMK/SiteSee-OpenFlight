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
import Combine

/// ViewModel that listen a drone and a remote control by default.
open class WatcherViewModel<T: ViewModelState>: BaseViewModel<T> {
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private unowned var currentRemoteControlHolder: CurrentRemoteControlHolder
    private unowned var currentDroneHolder: CurrentDroneHolder

    // MARK: - Public Properties
    /// Property which provides the current drone using currentDroneWatcher.
    public var drone: Drone? {
        return currentDroneHolder.drone
    }
    /// Property which provides the current remote control using currentRemoteControlWatcher.
    public var remoteControl: RemoteControl? {
        return currentRemoteControlHolder.remoteControl
    }

    // MARK: - Init
    public override init() {
        // TODO inject
        currentRemoteControlHolder = Services.hub.currentRemoteControlHolder
        currentDroneHolder = Services.hub.currentDroneHolder

        super.init()

        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                self.listenDrone(drone: drone)
            }
            .store(in: &cancellables)

        currentRemoteControlHolder.remoteControlPublisher
            .compactMap { $0 }
            .sink { [unowned self] remoteControl in
                listenRemoteControl(remoteControl: remoteControl)
            }
            .store(in: &cancellables)
    }

    // MARK: - Internal Funcs
    /// Method to override in subclass in order to listen drone instruments, peripherals, piloting interfaces, etc.
    internal func listenDrone(drone: Drone) {
        assert(false) // Must Override
    }

    /// Method to override in subclass in order to listen remote control instruments, peripherals, etc.
    internal func listenRemoteControl(remoteControl: RemoteControl) {
        assert(false) // Must Override
    }
}
