// Copyright (C) 2021 Parrot Drones SAS
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
import CoreData

extension DronesData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DronesData> {
        return NSFetchRequest<DronesData>(entityName: "DronesData")
    }

    // MARK: - Properties

    @NSManaged public var apcId: String!
    @NSManaged public var droneCommonName: String?
    @NSManaged public var droneSerial: String!
    @NSManaged public var modelId: String?
    @NSManaged public var pairedFor4G: Bool
    @NSManaged public var synchroDate: Date?
    @NSManaged public var synchroStatus: Int16

    // MARK: - Relationship

    @NSManaged public var ofUserParrot: UserParrot?

}

// MARK: - Utils
extension DronesData {

    /// Return DroneModel from DronesData type of NSManagedObject
    func model() -> DroneModel {
        return DroneModel(apcId: apcId,
                          droneSerial: droneSerial,
                          droneCommonName: droneCommonName,
                          modelId: modelId,
                          pairedFor4G: pairedFor4G,
                          synchroDate: synchroDate,
                          synchroStatus: synchroStatus)
    }
}
