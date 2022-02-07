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
import GroundSdk

public protocol FlightPlanFlightsRepository: AnyObject {

    /// Persist or update FlightPlanFlight into CoreData
    /// - Parameters:
    ///    - flightPlanFlight: FlightPlanFlightsModel to persist
    ///    - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ flightPlanFlight: FlightPlanFlightsModel, _ byUserUpdate: Bool)

    /// Persist or update flightPlanFlights into CoreData
    /// - Parameters:
    ///    - flightPlansFlightsList: flightsPlansFlightsModel to persist
    ///    - byUserUpdate: Bool to indicate in case of modifications, if those are made by User or by synchro process.
    func persist(_ flightPlansFlightsList: [FlightPlanFlightsModel], _ byUserUpdate: Bool)

    /// Load FlightPlanFlightsModel flagged tobeDeleted from CoreData
    /// - return:  FlightPlanFlightsModelList
    func loadFlightPlanFlightToRemove() -> [FlightPlanFlightsModel]

    /// Load FlightPlanFlight from CoreData by flightUuid and flightplanUuid
    /// - Parameters:
    ///     - flightUuid: flightUuid to search
    ///     - flightplanUuid: flightplanUuid to search
    /// - return:  FlightPlanFlightsModel object
    func loadFlightPlanFlight(_ flightUuid: String, _ flightplanUuid: String) -> FlightPlanFlightsModel?

    /// Load FlightPlanFlight from CoreData by Key and Value
    ///  Example: return the list of flight executions for a given FlightPlan Uuid
    /// - Parameters:
    ///     - Key:   Key identifier
    ///     - Value: Value of Key
    /// - return:  A list of FlightPlanFlightsModel
    func loadFlightPlanFlightKv(_ key: String, _ value: String) -> [FlightPlanFlightsModel]?

    /// Load all FlightsPlansFlights from CoreData
    /// - return : Array of FlightPlanFlightsModel
    func loadAllFlightsPlansFlights() -> [FlightPlanFlightsModel]

    /// Perform remove FlightPlanFlight from CoreData by flag
    /// Must have the two following params to can identify a unique FlightPlanFlight to remove
    /// - Parameters:
    ///     - flightUuid         : identify the Flight
    ///     - flightplanUuid: identify the FlightPlan
    func performRemoveFlightPlanFlight(_ flightUuid: String, _ flightplanUuid: String)

    /// Remove FlightPlanFlight from CoreData
    /// Must have the two following params to can identify a unique FlightPlanFlight to remove
    /// - Parameters:
    ///     - flightUuid         : identify the Flight
    ///     - flightplanUuid: identify the FlightPlan
    func removeFlightPlanFlight(_ flightUuid: String, _ flightplanUuid: String)

    /// Migrate FlightPlanFlights made by Anonymous user to current logged user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightPlanFlightsToLoggedUser(_ completion: @escaping () -> Void)

    /// Migrate FlightPlanFlights made by a Logged user to ANONYMOUS user
    /// - Parameter completion: empty block indicates when process is finished
    func migrateFlightPlanFlightsToAnonymous(_ completion: @escaping () -> Void)
}

extension CoreDataServiceImpl: FlightPlanFlightsRepository {

    public func persist(_ flightPlanFlight: FlightPlanFlightsModel, _ byUserUpdate: Bool = true) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let flightPlanFlightObject: NSManagedObject?

        // Check object if exists.
        if let object = self.flightPlanFlight(flightPlanFlight.flightUuid, flightPlanFlight.flightplanUuid, false) {
            // Use persisted object.
            flightPlanFlightObject = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            flightPlanFlightObject = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let flightPlanFlightObj = flightPlanFlightObject as? FlightPlanFlights else {
            ULog.e(.dataModelTag, "Failed to find or create flight plan flight")
            return
        }
        guard let flight = flight(flightPlanFlight.flightUuid) else {
            ULog.w(.dataModelTag, "Couldn't find flight \(flightPlanFlight.flightUuid) to create FlightPlanFlight")
            return
        }
        guard let flightPlan = flightPlan(flightPlanFlight.flightplanUuid) else {
            ULog.w(.dataModelTag, "Couldn't find flight plan \(flightPlanFlight.flightplanUuid) to create FlightPlanFlight")
            return
        }

        // To ensure synchronisation
        // reset `synchroStatus´ when the modifications are made by User
        flightPlanFlightObj.synchroStatus = ((byUserUpdate) ? 0 : flightPlanFlight.synchroStatus) ?? 0
        flightPlanFlightObj.synchroDate = flightPlanFlight.synchroDate
        flightPlanFlightObj.apcId = flightPlanFlight.apcId
        flightPlanFlightObj.flightUuid = flightPlanFlight.flightUuid
        flightPlanFlightObj.flightplanUuid = flightPlanFlight.flightplanUuid
        flightPlanFlightObj.dateExecutionFlight = flightPlanFlight.dateExecutionFlight
        flightPlanFlightObj.parrotCloudId = flightPlanFlight.parrotCloudId
        flightPlanFlightObj.parrotCloudToBeDeleted = flightPlanFlight.parrotCloudToBeDeleted
        flightPlanFlightObj.ofFlight = flight
        flightPlanFlightObj.ofFlightPlan = flightPlan

        managedContext.perform {
            do {
                try managedContext.save()
                if byUserUpdate {
                    self.objectToUpload.send(flightPlanFlight)
                }
            } catch let error {
                let fUuid = flightPlanFlight.flightUuid
                let fpUuid = flightPlanFlight.flightplanUuid
                ULog.e(.dataModelTag, "Error during persist FlightPlanFlight of FlightPlan: \(fpUuid) and Flight: \(fUuid) "
                       + "into Coredata: \(error.localizedDescription)")
            }
        }
    }

    public func persist(_ flightPlansFlightsList: [FlightPlanFlightsModel], _ byUserUpdate: Bool = true) {
        for flightPlanFlight in flightPlansFlightsList {
            self.persist(flightPlanFlight, byUserUpdate)
        }
    }

    public func loadFlightPlanFlightToRemove() -> [FlightPlanFlightsModel] {
        return loadflightPlanFlightsKv("apcId", userInformation.apcId, false)
            .filter({ $0.parrotCloudToBeDeleted })
            .compactMap({ $0.model() })
    }

    public func loadFlightPlanFlight(_ flightUuid: String, _ flightplanUuid: String) -> FlightPlanFlightsModel? {
        return flightPlanFlight(flightUuid, flightplanUuid)?.model()
    }

    public func loadFlightPlanFlightKv(_ key: String, _ value: String) -> [FlightPlanFlightsModel]? {
        return loadflightPlanFlightsKv(key, value)
            .map({$0.model()})
    }

    public func loadAllFlightsPlansFlights() -> [FlightPlanFlightsModel] {
        // Return FlightsPlansFlights of current User
        return loadflightPlanFlightsKv("apcId", userInformation.apcId)
            .map({ $0.model() })
    }

    public func performRemoveFlightPlanFlight(_ flightUuid: String, _ flightplanUuid: String) {
        guard let managedContext = currentContext,
              let flightPlanFlight = flightPlanFlight(flightUuid, flightplanUuid, false) else {
            return
        }

        if flightPlanFlight.parrotCloudId == 0 {
            managedContext.delete(flightPlanFlight)
        } else {
            flightPlanFlight.parrotCloudToBeDeleted = true
            objectToRemove.send(flightPlanFlight.model())
        }

        managedContext.delete(flightPlanFlight)

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error perform removing FlightPlanFlights with FlightUuid:\(flightUuid) and FlightPlanUuid:\(flightplanUuid)"
                        + " from CoreData:\(error.localizedDescription)")
            }
        }
    }

    public func removeFlightPlanFlight(_ flightUuid: String, _ flightplanUuid: String) {
        guard let flightPlanFlight = flightPlanFlight(flightUuid, flightplanUuid, false) else {
            return
        }
        removeFlightPlanFlight(flightPlanFlight)
    }

    public func migrateFlightPlanFlightsToLoggedUser(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateAnonymousDataToLoggedUser(for: entityName) {
            completion()
        }
    }

    public func migrateFlightPlanFlightsToAnonymous(_ completion: @escaping () -> Void) {
        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
        guard let entityName = fetchRequest.entityName else {
            return
        }
        migrateLoggedToAnonymous(for: entityName) {
            completion()
        }
    }
}

// MARK: - Utils
internal extension CoreDataServiceImpl {

    /// Return List of FlightPlanFlights type of NSManagedObject by Flight and FlightPlan if needed
    /// - Parameters:
    ///     - flightUuid: Uuid of flight
    ///     - flightplanUuid: Uuid of flightPlan
    ///     - onlyNotDeleted: flag to filter on flagged deleted object
    func flightPlanFlight(_ flightUuid: String?,
                          _ flightplanUuid: String?,
                          _ onlyNotDeleted: Bool = true) -> FlightPlanFlights? {
        guard let managedContext = currentContext,
              let flightUuid = flightUuid,
              let flightplanUuid = flightplanUuid else {
            return nil
        }

        var predicates: [NSPredicate] = []

        // fetch FlightPlanFlights by flightUuid and flightplanUuid
        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
        let predicate = NSPredicate(format: "flightUuid == %@ AND flightplanUuid == %@", flightUuid, flightplanUuid)
        predicates.append(predicate)

        if onlyNotDeleted {
            let predicate = NSPredicate(format: "parrotCloudToBeDeleted == %@", NSNumber(value: false))
            predicates.append(predicate)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: predicates)
        fetchRequest.predicate = compoundPredicates

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag,
                   "No FlightPlanFlights found with flightUuid: \(flightUuid) and flightplanUuid: \(flightplanUuid) in CoreData: \(error.localizedDescription)")
            return nil
        }
    }

    /// Return List of FlightPlanFlights type of NSManagedObject by Key and Value if needed
    /// - Parameters:
    ///     - key: key to search
    ///     - value: value of the key to search
    ///     - onlyNotDeleted: flag to filter on flagged deleted object
    func loadflightPlanFlightsKv(_ key: String? = nil,
                                 _ value: String? = nil,
                                 _ onlyNotDeleted: Bool = true) -> [FlightPlanFlights] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<FlightPlanFlights> = FlightPlanFlights.fetchRequest()
        var predicates: [NSPredicate] = []

        // fetch FlightPlanFlights by Key and Value
        if let key = key,
           let value = value {
            predicates.append(NSPredicate(format: "%K == %@", key, value))
        }

        if onlyNotDeleted {
            let predicate = NSPredicate(format: "parrotCloudToBeDeleted == %@", NSNumber(value: false))
            predicates.append(predicate)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: predicates)
        fetchRequest.predicate = compoundPredicates

        do {
            return try (managedContext.fetch(fetchRequest))
        } catch let error {
            ULog.e(.dataModelTag,
                   "No FlightPlanFlights found with \(key ?? ""): \(value ?? "") in CoreData: \(error.localizedDescription)")
            return []
        }
    }

    func removeFlightPlanFlight(_ flightPlanFlight: FlightPlanFlights) {
        guard let managedContext = currentContext else {
            return
        }
        managedContext.delete(flightPlanFlight)

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error removing FlightPlanFlights with FlightUuid:\(flightPlanFlight.flightUuid ?? "")"
                       + " and FlightPlanUuid:\(flightPlanFlight.flightplanUuid ?? "")"
                       + " from CoreData:\(error.localizedDescription)")
            }
        }
    }

}
