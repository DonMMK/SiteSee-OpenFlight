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
import UIKit
import Combine

// MARK: - Protocols
/// AccountProvider protocol
public protocol AccountProvider {
    /// Returns an image to show when needed (ie: on dashboard tile).
    var icon: UIImage { get }
    /// Returns a coordinator to start for the account details.
    var destinationCoordinator: Coordinator? { get }
    /// Returns a user avatar, if a user is connected.
    var userAvatar: UIImage? { get }
    /// Returns a user name, if a user is connected.
    var userName: String? { get }
    /// Returns if current user is connected or not.
    var isConnected: Bool { get }
    /// Returns custom dashboard account view.
    var dashboardAccountView: DashboardAccountView { get }
    /// Custom account view to display in MyFlightsVC.
    var myFlightsAccountView: MyFlightsAccountView? { get }
    /// Start Data confidentiality view from coordinator.
    func startDataConfidentiality()
    /// Start a specific view from coordinator when clicking on MyFlightsAccountView.
    func startMyFlightsAccountView()
    /// Remove flight, synchronized on the user's account.
    ///
    /// - Parameters:
    ///    - flightId: flight Id to remove
    ///    - completion: Callback with success
    func removeSynchronizedFlight(flightId: Int,
                                  completion: @escaping (Bool, Error?) -> Void)
    /// Remove Flight Plan, synchronized on the user's account.
    ///
    /// - Parameters:
    ///    - flightPlanId: flight Plan Id to remove
    ///    - completion: Callback with success
    func removeSynchronizedFlightPlan(flightPlanId: Int,
                                      completion: @escaping (Bool, Error?) -> Void)
}

/// MissionProvider protocol, dedicated to provide Mission content.
public protocol MissionProvider {
    /// Returns mission description.
    var mission: Mission { get }
    /// Returns mission signature
    var signature: ProtobufMissionSignature { get }

    /// Check if given the drone active mission uid, this mission should be activated in the app
    /// - Parameter missionUid: the drone active mission uid
    func isCompatibleWith(missionUid: String) -> Bool
}

public extension MissionProvider {
    func isCompatibleWith(missionUid: String) -> Bool { signature.missionUID == missionUid }
}

/// Protocol that defines a business item model used within the launcher in HUD.
public protocol MissionButtonState: BottomBarState {
    /// Button title.
    var title: String? { get }
    /// Button image.
    var image: UIImage? { get }
    /// Current provider value.
    var provider: MissionProvider? { get }
    /// Current mode, if exists.
    var mode: MissionMode? { get }
}

// MARK: Flight Plan Provider

public struct CustomFlightPlanProgress {
    public let color: UIColor
    public let progress: Double
    public let label: String

    public init(color: UIColor, progress: Double, label: String) {
        self.color = color
        self.progress = progress
        self.label = label
    }
}

/// FlightPlanProvider protocol, dedicated to provide Flight Plan specific content.
public protocol FlightPlanProvider {
    /// Project type
    var projectType: String { get }
    /// Project title.
    var projectTitle: String { get }
    /// New button title.
    var newButtonTitle: String { get }
    /// Create first title.
    var createFirstTitle: String { get }
    /// Flight Plan type.
    var typeKey: String { get }
    /// Predicate to filter stored Flight Plan, if needed.
    var filterPredicate: NSPredicate? { get }
    /// Edition type related to the Flight Plan.
    var settingsProvider: FlightPlanSettingsProvider? { get }
    /// Indicate if the settings view is always visible in edition mode.
    var settingsAlwaysDisplayed: Bool { get }
    /// Returns graphic items to diplay a Flight Plan.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight Plan model
    ///    - mapMode: map mode in which the Flight Plan will be displayed
    /// - Returns: Flight Plan Graphic array
    func graphicsWithFlightPlan(_ flightPlan: FlightPlanModel, mapMode: MapMode) -> [FlightPlanGraphic]
    /// Check if this provider manages a given flight plan type
    /// - Parameter type: the flight plan type
    func hasFlightPlanType(_ type: String) -> Bool
    /// Status view to be added to the FP panel
    var statusView: UIView? { get }
    /// Custom progress to take over classic progress when not nil
    var customProgressPublisher: AnyPublisher<CustomFlightPlanProgress?, Never> { get }
    /// Flight Plan execution title.
    var executionTitle: String { get }
}

/// Provides Flight Plan types.
public protocol FlightPlanSettingsProvider {
    /// Get current type.
    var currentType: FlightPlanType? { get }

    /// Returns all Flight Plan types.
    var allTypes: [FlightPlanType] { get }

    /// Returns all Flight Plan edition settings.
    var settings: [FlightPlanSetting] { get }

    /// Returns all Flight Plan edition settings categories.
    var settingsCategories: [FlightPlanSettingCategory] { get }

    /// Update the current type.
    ///
    /// - Parameters:
    ///     - tag: tag of the selected type
    func updateType(tag: Int)

    /// Update the current type.
    ///
    /// - Parameters:
    ///     - key: key of the selected type
    func updateType(key: String)

    /// Updates current settings value.
    ///
    /// - Parameters:
    ///     - key: current key for setting
    ///     - value: new value for setting
    func updateSettingValue(for key: String, value: Int)

    /// Updates current settings choice value.
    ///
    /// - Parameters:
    ///     - key: current choice key for setting
    ///     - value: current value for setting
    func updateChoiceSetting(for key: String, value: Bool)

    /// Returns the settings for a specific flight plan.
    ///
    /// - Parameters:
    ///     - flightPlan: The flight plan which we want the settings from
    /// - Returns: The settings of the flight plan
    func settings(for flightPlan: FlightPlanModel) -> [FlightPlanSetting]

    /// Returns the settings for a specific type of flight plan.
    ///
    /// - Parameters:
    ///     - type: The type of flight plan which we want the settings from
    /// - Returns: The settings for the type of flight plan
    func settings(for type: FlightPlanType) -> [FlightPlanSetting]
}

/// `FlightPlanSettingsProvider` utility extension.
extension FlightPlanSettingsProvider {
    /// Returns true if currrent Flight Plan has a custom type.
    var hasCustomType: Bool {
        if let type = currentType, type.key != ClassicFlightPlanType.standard.key {
            return true
        }
        return false
    }
}

/// Provides a Flight Plan setting.
public protocol FlightPlanSettingType {
    /// Provides flight plan setting title.
    var title: String { get }
    /// Provides flight plan setting short title.
    var shortTitle: String? { get }
    /// Provides all flight plan setting values.
    var allValues: [Int] { get }
    /// Provides custom descriptions for values.
    var valueDescriptions: [String]? { get }
    /// Provides images for values.
    var valueImages: [UIImage]? { get }
    /// Provides current flight plan setting value.
    var currentValue: Int? { get }
    /// Provides cell type of the current flight plan setting.
    var type: FlightPlanSettingCellType { get }
    /// Provides flight plan setting key.
    var key: String { get }
    /// Provides setting unit.
    var unit: UnitType { get }
    /// Provides setting step between values.
    var step: Double { get }
    /// Provides if values needs to be divided.
    var divider: Double { get }
    /// Tells if the setting must be disabled.
    var isDisabled: Bool { get }
    /// Provides cell category of the current flight plan setting.
    var category: FlightPlanSettingCategory { get }
}

/// Flight plan settings type utility extension.
extension FlightPlanSettingType {
    /// Returns the value with its unit.
    func valueToDisplay() -> String {
        return self.title + self.unit.unit
    }

    public var shortTitle: String? {
        return nil
    }

    var currentValueDescription: String? {
        switch self.type {
        case .choice:
            return currentValue == 0 ? L10n.commonYes : L10n.commonNo
        case .centeredRuler:
            guard let value = currentValue else { return nil }

            switch unit {
            case .distance:
                return UnitHelper.stringDistanceWithDouble(Double(value), spacing: false)
            case .speed:
                var doubleValue = Double(value)
                if divider <= 1.0 {
                    doubleValue *= divider
                }

                return UnitHelper.stringSpeedWithDouble(doubleValue, spacing: false)
            default:
                return "\(value)" + unit.unit
            }
        case .adjustement:
            guard let value = currentValue else { return nil }

            if step >= 1.0 {
                return String(format: "%d %@",
                              value,
                              unit.unit)
            } else {
                return String(format: "%.1f %@",
                              Double(value) * step,
                              unit.unit)
            }
        case .fixed:
            guard let value = currentValue else { return nil }
            return "\(value)" + unit.unit
        }
    }

    /// Returns a Flight Plan Setting.
    public func toFlightPlanSetting() -> FlightPlanSetting {
        return FlightPlanSetting(title: title,
                                 shortTitle: shortTitle,
                                 allValues: allValues,
                                 valueDescriptions: valueDescriptions,
                                 valueImages: valueImages,
                                 currentValue: currentValue,
                                 type: type,
                                 key: key,
                                 unit: unit,
                                 step: step,
                                 divider: divider,
                                 isDisabled: isDisabled,
                                 category: category)
    }

    /// Returns a Flight Plan Light Setting.
    public func toLightSetting() -> FlightPlanLightSetting {
        return FlightPlanLightSetting(key: self.key,
                                      currentValue: self.currentValue)
    }
}

/// Array extension for Flight Plan Light Setting.
extension Array where Element == FlightPlanSettingType {
    /// Returns an array of Flight Plan Light Settings.
    public func toLightSettings() -> [FlightPlanLightSetting] {
        return self.map({ $0.toLightSetting() })
    }

    /// Returns an array of Flight Plan Settings.
    public func toFlightPlanSettings() -> [FlightPlanSetting] {
        return self.map({ $0.toFlightPlanSetting() })
    }
}

/// Describes a Flight Plan type.
public protocol FlightPlanType {
    /// Type's title.
    var title: String { get }
    /// Type's icon.
    var icon: UIImage { get }
    /// Type's tag.
    var tag: Int { get }
    /// Type's key.
    var key: String { get }
    /// Allow generating MAVlink from Flight Plan.
    var canGenerateMavlink: Bool { get }
    /// Specify the type of the mavlink generation.
    var mavLinkType: FlightPlanInterpreter { get }
    /// Mission provider
    var missionProvider: MissionProvider { get }
    /// Mission mode
    var missionMode: MissionMode { get }
}

/// Provides a custom UIViewController displayed modally at Flight Plan's completion.
public protocol FlightPlanCompletionModalProvider {
    /// Returns custom modal to display.
    func customModal() -> UIViewController?
}

/// Protocols used to provide mission activation methods.
public protocol MissionActivationModel {
    /// Starts a Mission.
    func startMission()
    /// Stops a Mission if needed.
    func stopMissionIfNeeded()
}

/// Protocols used to provide camera configuration restrictions for a mission.
public protocol MissionCameraRestrictionsModel {
    /// Camera capture modes supported by the mission.
    var supportedModes: [CameraCaptureMode] { get }
    /// Camera recording framerates supported by the mission, by recording resolution.
    var supportedFrameratesByResolution: [Camera2RecordingResolution: Set<Camera2RecordingFramerate>]? { get }
}

// MARK: - Structs

/// Mission description.
public struct Mission {
    /// Returns mission key.
    var key: String
    /// Returns mission name.
    var name: String
    /// Returns mission icon.
    var icon: UIImage
    /// Log name.
    var logName: String
    /// Returns mission modes.
    public var modes: [MissionMode]

    /// Returns default mission mode.
    /// Mission have usually only one mode.
    public var defaultMode: MissionMode

    /// Default struct init, as public.
    public init(key: String,
                name: String,
                icon: UIImage,
                logName: String,
                modes: [MissionMode],
                defaultMode: MissionMode) {
        self.key = key
        self.name = name
        self.icon = icon
        self.logName = logName
        self.modes = modes
        self.defaultMode = defaultMode
    }

    /// Init with one mission mode, as public.
    public init(mode: MissionMode) {
        self.init(key: mode.key,
                  name: mode.name,
                  icon: mode.icon,
                  logName: mode.logName,
                  modes: [mode],
                  defaultMode: mode)
    }
}

/// Configurator for primary items of a MissionMode.
public struct MissionModeConfigurator {
    /// Returns mode key.
    var key: String
    /// Returns mode name.
    var name: String
    /// Returns mode icon.
    var icon: UIImage
    /// Log name.
    var logName: String
    /// Returns SplitScreenMode for this mode.
    var preferredSplitMode: SplitScreenMode
    /// Returns if map should always be visible instead of other right panel components.
    var isMapRequired: Bool
    /// Returns if FlightPlan panel is requiered for this mode.
    var isRightPanelRequired: Bool
    /// Returns the RTH title to show.
    var rthTitle: (ReturnHomeTarget?) -> String
    /// Returns if this mode is a Tracking one.
    var isTrackingMode: Bool

    /// Default struct init, as public.
    public init(key: String,
                name: String,
                icon: UIImage,
                logName: String,
                preferredSplitMode: SplitScreenMode,
                isMapRequired: Bool,
                isRightPanelRequired: Bool,
                rthTitle: ((ReturnHomeTarget?) -> String)? = nil,
                isTrackingMode: Bool) {
        self.key = key
        self.name = name
        self.icon = icon
        self.logName = logName
        self.preferredSplitMode = preferredSplitMode
        self.isMapRequired = isMapRequired
        self.isRightPanelRequired = isRightPanelRequired
        self.rthTitle = rthTitle ?? { target in
            switch target {
            case .controllerPosition:
                return L10n.alertReturnPilotTitle
            case .takeOffPosition:
                return L10n.alertReturnHomeTitle
            default:
                return L10n.alertReturnHomeTitle
            }
        }
        self.isTrackingMode = isTrackingMode
    }
}

public typealias HudRightPanelContentProvider = (_ services: ServiceHub,
                                                 _ splitControls: SplitControls,
                                                 _ rightPanelContainerControls: RightPanelContainerControls) -> Coordinator?
/// Mission Mode description.
public struct MissionMode: Equatable {
    /// Returns mission item key.
    public var key: String
    /// Returns mission item name.
    var name: String
    /// Returns mission item icon.
    var icon: UIImage
    /// Log name.
    var logName: String
    /// Returns preferred split screen mode.
    var preferredSplitMode: SplitScreenMode
    /// Returns if map should always be visible instead of other right panel components.
    var isMapRequired: Bool
    /// Returns true if HUD right panel is needed for this mode.
    var isRightPanelRequired: Bool
    /// Return a coordinator that should be inserted in the right panel if any
    var hudRightPanelContentProvider: HudRightPanelContentProvider
    /// Default map mode for this mission
    public var mapMode: MapMode
    /// Returns Flight Plan provider.
    public var flightPlanProvider: FlightPlanProvider? // TODO: make it smarter by directly handling current mission mode
    /// Returns a model for mission activation.
    public var missionActivationModel: MissionActivationModel
    /// Provides Return to Home Target type title.
    var rthTitle: (ReturnHomeTarget?) -> String
    /// Returns true if this mode is a tracking one.
    var isTrackingMode: Bool
    /// Returns an array of elements to display in the right stack of the bottom bar.
    var bottomBarRightStack: [ImagingStackElement]
    /// State machine
    public var stateMachine: FlightPlanStateMachine?
    /// Camera restrictions model for this mission, `nil` if there is no restrictions.
    public var cameraRestrictions: MissionCameraRestrictionsModel?

    // MARK: Completion handler properties
    /// Using completion handler properties to create variable only when they are called and not when instantiating the struct.
    /// Returns map view controller to show for this mission mode.
    public var customMapProvider: (() -> UIViewController?)?
    /// Returns custom coordinator to present at mode entry.
    public var entryCoordinatorProvider: (() -> Coordinator)?
    /// Returns an array of views to display in the left stackView on the bottom bar.
    var bottomBarLeftStack: (() -> [UIView])?

    /// Default struct init, as public.
    public init(configurator: MissionModeConfigurator,
                flightPlanProvider: FlightPlanProvider? = nil,
                missionActivationModel: MissionActivationModel = DefaultMissionActivationModel(),
                mapMode: MapMode = .standard(force2D: false),
                customMapProvider: (() -> UIViewController)? = nil,
                entryCoordinatorProvider: (() -> Coordinator)? = nil,
                bottomBarLeftStack: (() -> [UIView])?,
                bottomBarRightStack: [ImagingStackElement],
                stateMachine: FlightPlanStateMachine? = nil,
                hudRightPanelContentProvider: HudRightPanelContentProvider? = nil,
                cameraRestrictions: MissionCameraRestrictionsModel? = nil) {
        self.key = configurator.key
        self.name = configurator.name
        self.icon = configurator.icon
        self.logName = configurator.logName
        self.preferredSplitMode = configurator.preferredSplitMode
        self.isMapRequired = configurator.isMapRequired
        self.isRightPanelRequired = configurator.isRightPanelRequired
        self.rthTitle = configurator.rthTitle
        self.isTrackingMode = configurator.isTrackingMode
        self.mapMode = mapMode
        self.flightPlanProvider = flightPlanProvider
        self.missionActivationModel = missionActivationModel
        self.customMapProvider = customMapProvider
        self.entryCoordinatorProvider = entryCoordinatorProvider
        self.bottomBarLeftStack = bottomBarLeftStack
        self.bottomBarRightStack = bottomBarRightStack
        self.stateMachine = stateMachine
        self.hudRightPanelContentProvider = hudRightPanelContentProvider ?? { _, _, _ in nil }
        self.cameraRestrictions = cameraRestrictions
    }

    // MARK: - Equatable Implementation
    public static func == (lhs: MissionMode, rhs: MissionMode) -> Bool {
        return lhs.key == rhs.key
    }
}

// MARK: - Public Enums
/// Provides a view type for a Flight plan setting.
/// In a few words, it stores each type of display for a setting value.
public enum FlightPlanSettingCellType {
    case choice
    case adjustement
    case centeredRuler
    case fixed
}

/// Flight plan settings categories.
public enum FlightPlanSettingCategory: Hashable {
    case common
    case image
    case custom(String)

    /// Returns title category settings.
    var title: String {
        switch self {
        case .common:
            return L10n.flightPlanSettingsTitle
        case .image:
            return L10n.flightPlanMenuImage
        case .custom(let title):
            return title
        }
    }
}
