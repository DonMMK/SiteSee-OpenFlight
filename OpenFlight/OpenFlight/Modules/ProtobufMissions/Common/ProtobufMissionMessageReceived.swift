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

// MARK: ProtobufMissionMessage
/// A wrapper for GroundSDK `MissionMessage`: used to receive a message from a drone.
public struct ProtobufMissionMessageReceived: MissionMessage, Equatable {
    // MARK: - Public Properties
    public let missionUid: String
    public let messageUid: UInt
    public let serviceUid: UInt
    public let payload: Data

    // MARK: - Init
    /// Inits.
    ///
    /// - Parameter missionMessage: A mission message
    public init(missionMessage: MissionMessage) {
        self.missionUid = missionMessage.missionUid
        self.messageUid = missionMessage.messageUid
        self.serviceUid = missionMessage.serviceUid
        self.payload = missionMessage.payload
    }

    // MARK: - Equatable
    public static func == (lhs: ProtobufMissionMessageReceived,
                           rhs: ProtobufMissionMessageReceived) -> Bool {
        return lhs.missionUid == rhs.missionUid
            && lhs.messageUid == rhs.messageUid
            && lhs.serviceUid == rhs.serviceUid
            && lhs.payload == rhs.payload
    }
}
