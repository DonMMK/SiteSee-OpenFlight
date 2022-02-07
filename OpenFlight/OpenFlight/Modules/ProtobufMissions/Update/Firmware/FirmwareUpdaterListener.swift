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

import Foundation
import GroundSdk

/// The global possible states of a Firmware update process.
enum FirmwareGlobalUpdatingState {
    case notInitialized
    case ongoing
    case downloading
    case uploading
    case processing
    case waitingForReboot
    case success
    case error
}

/// Typealias for listener callback signature.
typealias FirmwareUpdaterClosure = (_ : FirmwareGlobalUpdatingState) -> Void

// MARK: - FirmwareUpdaterListener
/// A listener to listen to a change during a Firmware update/download.
final class FirmwareUpdaterListener: NSObject {
    // MARK: - Internal Properties
    /// The callback that will be called when a change occurs during the Firmware update/download.
    let firmwareToUpdateCallback: FirmwareUpdaterClosure

    // MARK: - Init
    /// Inits the listener.
    ///
    /// - Parameters:
    ///   - firmwareToUpdateCallback: The callback that will be trigger when a change occurs during the Firmware update/download.
    init(firmwareToUpdateCallback: @escaping FirmwareUpdaterClosure) {
        self.firmwareToUpdateCallback = firmwareToUpdateCallback
    }
}
