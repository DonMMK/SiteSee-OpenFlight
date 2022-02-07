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

public class ProjectManagerViewModel {

    // MARK: - Public properties
    public var allProjects: AnyPublisher<[ProjectModel], Never> { manager.projectsPublisher }
//    public var filteredProjects: AnyPublisher<[ProjectModel], Never> { manager.projectsPublisher }
    public var isSynchronizingData: AnyPublisher<Bool, Never> { isSynchronizingSubject.eraseToAnyPublisher() }
    public var isFlightPlanProjectType: AnyPublisher<Bool, Never> { isFlightPlanProjectTypeSubject.eraseToAnyPublisher() }
    public var projectDidUpdate: AnyPublisher<ProjectModel?, Never> { projectDidUpdateSubject.eraseToAnyPublisher() }
    public var projectAdded: AnyPublisher<ProjectModel?, Never> { projectAddedSubject.eraseToAnyPublisher() }

    let manager: ProjectManager
    let cloudSynchroWatcher: CloudSynchroWatcher?

    // MARK: - Private properties
    private let coordinator: DashboardCoordinator?
    private let projectManagerUiProvider: ProjectManagerUiProvider!
    private var isSynchronizingSubject = CurrentValueSubject<Bool, Never>(false)
    private var isFlightPlanProjectTypeSubject = CurrentValueSubject<Bool, Never>(true)
    private var projectDidUpdateSubject = CurrentValueSubject<ProjectModel?, Never>(nil)
    private var projectAddedSubject = CurrentValueSubject<ProjectModel?, Never>(nil)
    private var idFlyingProject: String?
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: DashboardCoordinator?,
         manager: ProjectManager,
         cloudSynchroWatcher: CloudSynchroWatcher?,
         projectManagerUiProvider: ProjectManagerUiProvider) {
        self.manager = manager
        self.cloudSynchroWatcher = cloudSynchroWatcher
        self.coordinator = coordinator
        self.projectManagerUiProvider = projectManagerUiProvider

        listenDataSynchronization()
    }

    // MARK: - Private funcs
    private func listenDataSynchronization() {
        cloudSynchroWatcher?.isSynchronizingDataPublisher
            .sink { [unowned self] isSynch in
                isSynchronizingSubject.value = isSynch
            }
            .store(in: &cancellables)
    }

    private func listenFlightPlanStateMachine() {
        Services.hub.flightPlan.stateMachine.statePublisher
            .sink(receiveValue: { [unowned self] state in
                switch state {
                case let .flying(flightPlan):
                    idFlyingProject = flightPlan.projectUuid
                default:
                    idFlyingProject = nil
                }
            })
            .store(in: &cancellables)
    }

 }

extension ProjectManagerViewModel {
    func updateProjectType(_ projectType: ProjectManagerUiParameters.ProjectType) {
        isFlightPlanProjectTypeSubject.value = projectType.isStantardFlightPlan
    }

    var projectTypes: [ProjectManagerUiParameters.ProjectType] { projectManagerUiProvider.uiParameters().projectTypes }

    func index(of projectType: ProjectManagerUiParameters.ProjectType?) -> Int? {
        guard let projectType = projectType else { return nil }
        return projectTypes.firstIndex(where: { $0.title == projectType.title })
    }

    func projectType(for index: Int?) -> ProjectManagerUiParameters.ProjectType? {
        guard let index = index else { return projectTypes.first }
        return projectTypes[min(max(index, 0), projectTypes.count)]
    }
}

// MARK: - Project actions
extension ProjectManagerViewModel {

    func openProject(_ project: ProjectModel) {
        coordinator?.open(project: project)
    }

    func renameProject(_ project: ProjectModel, with title: String?) {
        manager.rename(project, title: title)
        projectDidUpdateSubject.value = project
    }

    func duplicateProject(_ project: ProjectModel) {
        manager.duplicate(project: project)
        projectAddedSubject.value = manager.currentProject
   }

    func createNewProject(for flightPlanProvider: FlightPlanProvider) {
        let project = manager.newProject(flightPlanProvider: flightPlanProvider)
        projectAddedSubject.value = project
    }

    func shhowDeletionConfirmation(for project: ProjectModel) {
        coordinator?.showDeleteProjectPopupConfirmation(didTapDelete: {
            self.deleteProject(project)
        })
     }

    func deleteProject(_ project: ProjectModel) {
        // TODO: Inform user he can't delete a project in use.
        guard canDeleteProject(project) else { return }
        manager.delete(project: project)
        projectDidUpdateSubject.value = nil
    }

    func canDeleteProject(_ project: ProjectModel) -> Bool {
        project.uuid != idFlyingProject
    }

 }
