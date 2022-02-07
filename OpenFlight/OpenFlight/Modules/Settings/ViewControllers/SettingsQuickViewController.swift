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

import UIKit
import Reusable
import GroundSdk

/// This is a specific settings display (collection view) used as shortcuts.
/// Quick settings will reuse as much a possible setting content and its children logic.
final class SettingsQuickViewController: UIViewController, StoryboardBased {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!

    // MARK: - Private Properties
    // TODO wrong injection, viewModel should be prepared one level up (coordinator or upper VM)
    private let viewModel = QuickSettingsViewModel(obstacleAvoidanceMonitor: Services.hub.obstacleAvoidanceMonitor)
    private var settings: [SettingEntry] = [] {
        didSet {
            collectionView?.reloadData()
            self.collectionView.isUserInteractionEnabled = true
        }
    }
    private var filteredSettings: [SettingEntry] {
        return settings.filter({ $0.setting != nil })
    }
    private var valueInterSpaceItem: CGFloat = 20
    private var valueInterLineRowItem: CGFloat = 20
    private var valueMaxItemsPerRow: CGFloat = 3

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        // watch current drone.
        viewModel.state.valueChanged = { [weak self] _ in
            self?.updateCells()
        }
        updateCells()
        setupCollectionViewLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCollectionViewLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupCollectionViewLayout()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    private func setupCollectionViewLayout() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        layout.estimatedItemSize = CGSize.zero
        let maxItemPerRow: CGFloat = valueMaxItemsPerRow
        // collection.width divide by 3 items means 2 inter space in the row.
        let maxItemForInterLine = maxItemPerRow > 1 ? maxItemPerRow - 1 : 1

        // get width of item for one row.
        let itemSizeCustom = (collectionView.frame.size.width / maxItemPerRow )
        let spaceInterItemCustom: CGFloat = (valueInterSpaceItem / maxItemPerRow) * (maxItemForInterLine)
        let spaceInterLineCustom: CGFloat = valueInterLineRowItem

        // Alignment
        let deltaHeight = collectionView.frame.height - (itemSizeCustom * (CGFloat(filteredSettings.count) / valueMaxItemsPerRow))
        // try to center some elements vertically, otherwise it is set to 0 or you can set a constant value.
        layout.sectionInset.top = deltaHeight / 2 < 0 ? 0 : deltaHeight / 2
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = spaceInterItemCustom
        layout.minimumLineSpacing = spaceInterLineCustom

        layout.itemSize = CGSize(width: itemSizeCustom - spaceInterItemCustom, height: itemSizeCustom - spaceInterItemCustom)

        collectionView.register(cellType: SettingsQuickCollectionViewCell.self)
    }

    private func updateCells() {
        settings = viewModel.settingEntries
    }
}

// MARK: - UICollectionView DataSource
extension SettingsQuickViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredSettings.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: SettingsQuickCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)

        let settingEntry = filteredSettings[indexPath.row]
        cell.configureCell(settingEntry: settingEntry, atIndexPath: indexPath, delegate: self)
        cell.backgroundColor = settingEntry.bgColor

        return cell
    }
}

// MARK: - Settings quick collection view cell delegate
extension SettingsQuickViewController: SettingsQuickCollectionViewCellDelegate {
    func settingsQuickCelldidTap(indexPath: IndexPath) {
        let settingEntry = filteredSettings[indexPath.row]

        if let model = settingEntry.segmentModel {
            viewModel.saveSettingsEntry(settingEntry, at: model.nextIndex)
        }
    }
}
