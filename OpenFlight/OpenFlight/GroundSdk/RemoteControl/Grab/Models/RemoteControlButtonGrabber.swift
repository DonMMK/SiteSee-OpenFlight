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

/// Class that grabs a specific button of the remote control.

public final class RemoteControlButtonGrabber {
    // MARK: - Private Properties
    private var button: SkyCtrl4Button
    private var event: SkyCtrl4ButtonEvent
    private var key: String
    private var action: ((SkyCtrl4ButtonEventState) -> Void)?
    private(set) var isRemoteControlGrabbed = false

    // MARK: - Init
    private init() { fatalError("forbidden") }

    /// Init.
    ///
    /// - Parameters:
    ///    - button: button to grab
    ///    - event: event for which a custom action is defined
    ///    - key: unique key (e.g. class description concatenated with event description)
    ///    - action: custom action block
    public init(button: SkyCtrl4Button,
                event: SkyCtrl4ButtonEvent,
                key: String,
                action: ((SkyCtrl4ButtonEventState) -> Void)? = nil) {
        self.button = button
        self.event = event
        self.key = key
        self.action = action
    }

    // MARK: - Public Funcs
    /// Called when remote control button should be grabbed.
    public func grab() {
        guard !isRemoteControlGrabbed else { return }

        RemoteControlGrabManager.shared.grabButton(button)
        if let action = action {
            RemoteControlGrabManager.shared.addAction(for: event, key: key, action: action)
        }

        isRemoteControlGrabbed = true
    }

    /// Called when remote control button should be ungrabbed.
    public func ungrab() {
        guard isRemoteControlGrabbed else { return }

        RemoteControlGrabManager.shared.ungrabButton(button)
        RemoteControlGrabManager.shared.removeAction(for: event, key: key)
        isRemoteControlGrabbed = false
    }
}
