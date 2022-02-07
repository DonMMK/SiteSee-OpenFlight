// Copyright (C) 2020 Parrot Drones SAS
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
import Combine

public protocol FlightPlanManager {

    /// Duplicates Flight Plan.
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to duplicate
    /// - Returns: the new version of duplicat flight plan
    func duplicate(flightPlan: FlightPlanModel) -> FlightPlanModel

    /// Deletes a flightPlan.
    ///
    /// - Parameters:
    ///     - flightPlan: flight plan to delete
    func delete(flightPlan: FlightPlanModel)

    /// Updates flightplan state and saves it in CoreData
    ///
    /// - Parameters:
    ///     - flightplan: flight plan to update
    ///     - state: update the flightplan with this new state
    func update(flightplan: FlightPlanModel, with state: FlightPlanModel.FlightPlanState) -> FlightPlanModel

    /// Updates flightplan lastMissionItemExecuted
    /// - Parameters:
    ///   - flightPlan: flight plan
    ///   - lastMissionItemExecuted: last item executed
    func update(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int) -> FlightPlanModel

    /// Saves drone progress
    ///
    func saveExecutionProgress(for flightPlan: FlightPlanModel, at waypoint: Int) -> FlightPlanModel

    /// Get all Editable flightplans linked to a specific project
    ///
    /// - parameters:
    ///     - projectId: project to consider
    /// - Returns: List of flight plans ordered by lastUpdate
    func editableFlightPlansFor(projectId: String) -> [FlightPlanModel]

    /// Updates a flight plan with **lastUploadAttempt** set to today date and **uploadAttemptCount** incremented
    ///
    /// - Parameter flightplan: flight plan to be updated
    /// - Returns: Flight plan updated
    func updateWithUploadAttempt(flightplan: FlightPlanModel) -> FlightPlanModel

    /// Gets a flight plan given its uuid
    /// - Parameter uuid: uuid of the flight plan
    func flightPlan(uuid: String) -> FlightPlanModel?

    /// Gets a flight plan given its pgyId
    /// - Parameter pgyId: pgyId of a project
    func flightPlanWith(pgyId: Int64) -> FlightPlanModel?

    /// Gets all flight plans according to a specific state
    /// - Parameter state: state to filter
    func flightPlansForState(_ state: FlightPlanModel.FlightPlanState) -> [FlightPlanModel]

    /// Get the last flight date of a flight plan if any
    /// - Parameter flightPlan: flight plan
    func lastFlightDate(_ flightPlan: FlightPlanModel) -> Date?
}

public class FlightPlanManagerImpl: FlightPlanManager {
    private let persistenceFlightPlan: FlightPlanRepository
    private let currentUser: UserInformation
    private let filesManager: FlightPlanFilesManager
    private let pgyProjectRepo: PgyProjectRepository

    public init(persistenceFlightPlan: FlightPlanRepository,
                currentUser: UserInformation,
                filesManager: FlightPlanFilesManager,
                pgyProjectRepo: PgyProjectRepository) {
        self.persistenceFlightPlan = persistenceFlightPlan
        self.currentUser = currentUser
        self.filesManager = filesManager
        self.pgyProjectRepo = pgyProjectRepo
    }

    // MARK: - Private Functions

    private func persist(_ flightPlan: FlightPlanModel) {
        persistenceFlightPlan.persist(flightPlan, true)
    }

    // MARK: - Public Functions

    public func duplicate(flightPlan: FlightPlanModel) -> FlightPlanModel {

        flightPlan.dataSetting?.mavlinkDataFile = nil
        let thumbnailUUID = UUID().uuidString

        var duplicatedFlightPlan = flightPlan
        duplicatedFlightPlan.uuid = UUID().uuidString
        duplicatedFlightPlan.lastUpdate = Date()
        duplicatedFlightPlan.state = .editable
        duplicatedFlightPlan.lastMissionItemExecuted = 0
        duplicatedFlightPlan.pgyProjectId = 0
        duplicatedFlightPlan.uploadedMediaCount = 0
        duplicatedFlightPlan.parrotCloudId = 0
        duplicatedFlightPlan.parrotCloudToBeDeleted = false
        duplicatedFlightPlan.parrotCloudUploadUrl = nil
        duplicatedFlightPlan.synchroDate = nil
        duplicatedFlightPlan.thumbnail = ThumbnailModel(apcId: currentUser.apcId,
                                                        uuid: thumbnailUUID,
                                                        thumbnailImage: flightPlan.thumbnail?.thumbnailImage)
        duplicatedFlightPlan.thumbnailUuid = thumbnailUUID
        duplicatedFlightPlan.flightPlanFlights = []
        duplicatedFlightPlan.dataSetting?.notPropagatedSettings = [:]

        persist(duplicatedFlightPlan)
        return duplicatedFlightPlan
    }

    public func delete(flightPlan: FlightPlanModel) {
        if flightPlan.pgyProjectId > 0 {
            pgyProjectRepo.removePgyProject(flightPlan.pgyProjectId)
        }
        filesManager.deleteMavlink(of: flightPlan)
        persistenceFlightPlan.performRemoveFlightPlan(flightPlan)
    }

    public func editableFlightPlansFor(projectId: String) -> [FlightPlanModel] {
        persistenceFlightPlan.loadFlightPlans(["projectUuid": projectId, "state": FlightPlanModel.FlightPlanState.editable.rawValue])
    }

    public func flightPlansForState(_ state: FlightPlanModel.FlightPlanState) -> [FlightPlanModel] {
        persistenceFlightPlan.loadFlightPlansByExcluding(types: ["default"]).filter { $0.state.rawValue == state.rawValue }
    }

    public func updateWithUploadAttempt(flightplan: FlightPlanModel) -> FlightPlanModel {
        var updatedFlightplan = flightplan
        updatedFlightplan.lastUploadAttempt = Date()
        updatedFlightplan.uploadAttemptCount += 1
        persist(updatedFlightplan)
        return updatedFlightplan
    }

    public func update(flightplan: FlightPlanModel, with state: FlightPlanModel.FlightPlanState) -> FlightPlanModel {
        var newStateFlightPlan = flightplan
        newStateFlightPlan.state = state
        persist(newStateFlightPlan)
        return newStateFlightPlan
    }

    public func update(flightPlan: FlightPlanModel, lastMissionItemExecuted: Int) -> FlightPlanModel {
        var newFlightPlan = flightPlan
        newFlightPlan.lastMissionItemExecuted = Int64(lastMissionItemExecuted)
        self.persistenceFlightPlan.persist(newFlightPlan, true)
        return newFlightPlan
    }

    public func saveExecutionProgress(for flightPlan: FlightPlanModel, at waypoint: Int) -> FlightPlanModel {
        var updatedFlightplan = flightPlan
        updatedFlightplan.lastMissionItemExecuted = Int64(waypoint)
        updatedFlightplan.state = .flying
        persistenceFlightPlan.persist(updatedFlightplan, true)
        return updatedFlightplan
    }

    public func flightPlan(uuid: String) -> FlightPlanModel? {
        persistenceFlightPlan.loadFlightPlan("uuid", uuid)
    }

    public func flightPlanWith(pgyId: Int64) -> FlightPlanModel? {
        persistenceFlightPlan.loadFlightPlansByPgyProject(pgyProjectId: pgyId)
    }

    public func lastFlightDate(_ flightPlan: FlightPlanModel) -> Date? {
        persistenceFlightPlan.lastFlightDate(flightPlan)
    }
}
