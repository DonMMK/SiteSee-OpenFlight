//
//
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

import Foundation
import Combine

public class ProjectsListViewModel {

    @Published private(set) var filteredProjects: [ProjectModel] = [ProjectModel]()
    @Published private(set) var selectedProject: ProjectModel? {
        didSet {
            guard let project = selectedProject else {
                manager.clearCurrentProject()
                return
            }
            manager.setCurrent(project)
        }
    }
    private var allProjects: [ProjectModel] = [ProjectModel]()

    let manager: ProjectManager
    private let projectManagerViewModel: ProjectManagerViewModel?
    private let cloudSynchroWatcher: CloudSynchroWatcher?
    private let coordinator: DashboardCoordinator?
    private var isFlightPlanProjectType: Bool = true
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: DashboardCoordinator?,
         manager: ProjectManager,
         cloudSynchroWatcher: CloudSynchroWatcher?,
         projectManagerViewModel: ProjectManagerViewModel) {
        self.coordinator = coordinator
        self.manager = manager
        self.projectManagerViewModel = projectManagerViewModel
        self.cloudSynchroWatcher = cloudSynchroWatcher

        updateProjects()
        selectedProject = nil
        listenProjectTypeChange()
        listenCloudSynchroWatcherChange()
        listenProjectsChange()
    }

    // MARK: - Private funcs
    private func listenProjectTypeChange() {
        projectManagerViewModel?.isFlightPlanProjectType
            .sink { [unowned self] isFlightPlanType in
                selectedProject = nil
                isFlightPlanProjectType = isFlightPlanType
                updateProjects()
            }
            .store(in: &cancellables)
    }

    private func listenCloudSynchroWatcherChange() {
        cloudSynchroWatcher?.isSynchronizingDataPublisher.sink(receiveValue: { [unowned self] isSynchronizingData in
            if !isSynchronizingData {
                updateProjects()
            }
        }).store(in: &cancellables)
    }

    private func listenProjectsChange() {
        projectManagerViewModel?.projectDidUpdate
            .sink { [unowned self] projectUpdated in
                updateProjects()
                selectedProject = project(with: projectUpdated?.uuid)
            }
            .store(in: &cancellables)

        projectManagerViewModel?.projectAdded
            .sink { [unowned self] projectAdded in
                updateProjects()
                selectedProject =  project(with: projectAdded?.uuid)
           }
            .store(in: &cancellables)
    }

    private func updateProjects() {
        allProjects = getAllProjects()
        filteredProjects = isFlightPlanProjectType ?
            allProjects.filter({ $0.isSimpleFlightPlan }) :
            allProjects.filter({ !$0.isSimpleFlightPlan })
    }

    private func project(with uuid: String?) -> ProjectModel? {
        guard let uuid = uuid else { return nil }
        return filteredProjects.first { $0.uuid == uuid }
    }

    private func getAllProjects() -> [ProjectModel] { manager.loadProjects(type: nil) }

    // MARK: - Public funcs
    func didSelect(project: ProjectModel) {
        selectedProject = project
    }

    func didDeselectProject() {
        selectedProject = nil
    }

    func isProjectSelected(_ project: ProjectModel) -> Bool {
        project.uuid == selectedProject?.uuid
    }
}
