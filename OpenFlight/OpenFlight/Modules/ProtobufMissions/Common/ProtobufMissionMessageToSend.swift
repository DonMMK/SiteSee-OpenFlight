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
/// A wrapper for GroundSDK `MissionMessage`: used to send message to the drone.
public struct ProtobufMissionMessageToSend: MissionMessage {
    // MARK: - Public Properties
    public let missionUid: String
    public let messageUid: UInt
    public let serviceUid: UInt
    public let payload: Data

    /// Incrementing integer generator
    public struct UidGenerator: IteratorProtocol {
        private var counter: UInt = 0

        public init(_ counter: UInt) {
            self.counter = counter
        }

        public mutating func next() -> UInt? {
            let uid = counter
            counter += 1
            return uid
        }
    }

    // MARK: - Init
    /// Inits.
    /// - Parameters:
    ///   - mission: The related mission
    ///   - payload: The payload
    public init(mission: ProtobufMissionSignature,
                payload: Data,
                messageUidGenerator: inout UidGenerator) {
        self.missionUid = mission.missionUID
        self.messageUid = messageUidGenerator.next() ?? 0
        self.serviceUid = mission.serviceUidCommand
        self.payload = payload
    }
}
