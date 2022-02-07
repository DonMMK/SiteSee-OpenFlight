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

// MARK: - Internal Enums
/// Model for `StereoVisionSensorsCalibrationState`.
enum StereoVisionSensorsCalibrationState {
    case calibrated
    case needed
    case unavailable

    /// String describing front stereo vision sensors calibration state.
    var description: String {
        switch self {
        case .calibrated,
             .unavailable:
            return ""
        case .needed:
            return L10n.commonRequired
        }
    }

    /// Color for stereo vision sensors calibration subtext cell.
    var subtextColor: ColorName {
        return self == .needed ? .white : .defaultTextColor
    }

    /// Background color for stereo vision sensors calibration cell.
    var backgroundColor: ColorName {
        return self == .needed ? .errorColor : .white
    }

    /// Image for stereo vision sensors calibration.
    var calibrationImage: UIImage? {
        switch self {
        case .calibrated:
            return Asset.Drone.icDroneStereoVisionOk.image
        case .needed:
            return Asset.Drone.icDroneStereoVisionWarning.image
        case .unavailable:
            return nil
        }
    }

    /// User interaction state for calibration view.
    var isUserInteractionEnabled: Bool {
        return self == .needed
    }
}
