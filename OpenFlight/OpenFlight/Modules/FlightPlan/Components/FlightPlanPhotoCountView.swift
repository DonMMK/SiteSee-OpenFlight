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

import UIKit
import Reusable

/// Displays number of photos taken during a flight plan execution.
final class FlightPlanPhotoCountView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var photoCountLabel: UILabel! {
        didSet {
            photoCountLabel.makeUp(and: .defaultTextColor)
        }
    }

    // MARK: - Private Properties
    private var viewModel: FlightPlanPhotoCountViewModel?

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitFlightPlanPhotoCountView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitFlightPlanPhotoCountView()
    }

    // MARK: - Internal Funcs
    /// Sets up the cell.
    ///
    /// - Parameters:
    ///     - flightModel: the flight plan model
    func setup(flightModel: FlightPlanModel) {
        initViewModel(flightModel: flightModel)
    }
}

// MARK: - Private Funcs
private extension FlightPlanPhotoCountView {
    /// Common init.
    func commonInitFlightPlanPhotoCountView() {
        self.loadNibContent()

        self.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                radius: Style.mediumCornerRadius)
    }

    /// Inits the view model.
    ///
    /// - Parameters:
    ///     - flightModel: the flight plan model
    func initViewModel(flightModel: FlightPlanModel) {
        viewModel = FlightPlanPhotoCountViewModel(flightModel: flightModel)
        viewModel?.state.valueChanged = { [weak self] state in
            self?.updateView(state: state)
        }
        updateView(state: viewModel?.state.value)
    }

    /// Updates photo count view.
    ///
    /// - Parameters:
    ///     - state: flight plan photo count state
    func updateView(state: FlightPlanPhotoCountState?) {
        photoCountLabel.text = state?.photoNumberDesc
    }
}
