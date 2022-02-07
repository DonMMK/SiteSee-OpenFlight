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
import UIKit
import Reusable
import GroundSdk

// MARK: - Public Protocols
protocol HelloWorldStartAndStopViewDelegate: AnyObject {
    func didClickOnStartAndStop()
}

/// A view to interact with the Hello World Protobuf mission.
class HelloWorldStartAndStopView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var startAndStopButton: UIButton!
    @IBOutlet private weak var containerView: UIView!

    // MARK: - Private Properties
    private var currentState: HellowWorldStartAndStopState = .active

    // MARK: - Private Enums
    /// Exhaustive states for `HelloWorldStartAndStopView`.
    private enum HellowWorldStartAndStopState {
        case waiting
        case active
    }

    // MARK: - Internal Properties
    weak var delegate: HelloWorldStartAndStopViewDelegate?

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitStopView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitStopView()
    }
}

// MARK: - Internal Funcs
extension HelloWorldStartAndStopView {
    /// Updates the view layout.
    ///
    /// - Parameters:
    ///   - state: The current Hello World state
    ///   - didReceiveMessage: A boolean to indicate if we received a message from the drone
    func update(with state: MissionState,
                didReceiveMessage: Bool) {
        switch state {
        case .active:
            currentState = didReceiveMessage ? .active : .waiting
            switch currentState {
            case .active:
                startAndStopButton.setImage(Asset.Common.Icons.stop.image, for: .normal)
                containerView.backgroundColor = ColorName.redTorch.color
            case .waiting:
                startAndStopButton.setImage(Asset.Common.Icons.play.image, for: .normal)
                containerView.backgroundColor = ColorName.greenHaze.color
            }
        case .idle:
            currentState = .waiting
            startAndStopButton.setImage(Asset.Common.Icons.play.image, for: .normal)
            containerView.backgroundColor = ColorName.greenHaze.color
        case .unavailable:
            currentState = .waiting
            startAndStopButton.setImage(Asset.Common.Icons.icUndo.image, for: .normal)
            containerView.backgroundColor = ColorName.orangePeel.color
        case .unloaded:
            currentState = .waiting
            startAndStopButton.setImage(Asset.Common.Icons.icUndo.image, for: .normal)
            containerView.backgroundColor = ColorName.orangePeel.color
        }
    }
}

// MARK: - Private Funcs
private extension HelloWorldStartAndStopView {
    func commonInitStopView() {
        self.loadNibContent()

        self.initUI()
    }

    /// Inits the layout.
    func initUI() {
        startAndStopButton.setImage(Asset.Common.Icons.icUndo.image, for: .normal)
        containerView.backgroundColor = ColorName.orangePeel.color
        customCornered(corners: [.topRight, .bottomRight],
                       radius: Style.largeCornerRadius,
                       backgroundColor: .clear,
                       borderColor: .clear)
    }
}

// MARK: - Actions
private extension HelloWorldStartAndStopView {
    @IBAction func startAndStopButtonTouchedUpInside(_ sender: Any) {
        delegate?.didClickOnStartAndStop()
    }
}
