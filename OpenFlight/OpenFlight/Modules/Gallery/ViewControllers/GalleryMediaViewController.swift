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
import GroundSdk

// MARK: - Protocols
/// Delegate used to discuss with main controller.
protocol GalleryMediaViewDelegate: AnyObject {
    /// Called when an action was triggered by the multiple selection.
    func multipleSelectionActionTriggered()
    /// Called when the multiple selection is enabled from here.
    func multipleSelectionEnabled()
    func didUpdateMediaSelection(count: Int, size: UInt64)
}

/// Displays medias.

final class GalleryMediaViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collection: UICollectionView!
    @IBOutlet private weak var loadingView: GalleryLoadingView!
    @IBOutlet private weak var selectionView: GallerySelectionView!

    // MARK: - Private Properties
    private var dataSource: [(key: Date, medias: [GalleryMedia])] = []
    private weak var coordinator: GalleryCoordinator?
    private weak var viewModel: GalleryMediaViewModel?
    private var loadingMedias: [GalleryMedia] = []
    private var unsortedMedias: [GalleryMedia] {
        dataSource.map({ $0.medias }).flatMap({ $0 })
    }
    private var selectedMedias: [GalleryMedia] = [] {
        didSet {
            delegate?.didUpdateMediaSelection(count: selectedMedias.count,
                                              size: selectedMediasSize)
        }
    }
    private var selectedMediasSize: UInt64 {
        return selectedMedias.reduce(0) { $0 + $1.size }
    }

    // MARK: - Internal Properties
    weak var delegate: GalleryMediaViewDelegate?

    // MARK: - Private Enums
    private enum Constants {
        static let nbColumnsLandscape: CGFloat = 4.0
        static let nbColumnsPortrait: CGFloat = 2.0
        static let itemSpacing: CGFloat = 2.0
        static let cellWidthRatio: CGFloat = 1.0
        static let headerHeight: CGFloat = 26.0
        static let longPressDuration: TimeInterval = 0.5
        static let collectionViewInsets: UIEdgeInsets = .init(top: 0, left: 12, bottom: 12, right: 12)
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    /// - Returns: a GalleryMediaViewController.
    static func instantiate(coordinator: GalleryCoordinator, viewModel: GalleryMediaViewModel) -> GalleryMediaViewController {
        let viewController = StoryboardScene.GalleryComponentsViewController.galleryMediaViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .clear
        setupCollection()
        loadingView.delegate = self
        selectionView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel?.refreshMedias(source: viewModel?.sourceType)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        collection.reloadData()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension GalleryMediaViewController {
    /// Setup collection.
    func setupCollection() {
        collection.register(cellType: GalleryMediaCollectionViewCell.self)
        collection.register(supplementaryViewType: GalleryMediaCollectionReusableView.self,
                            ofKind: UICollectionView.elementKindSectionHeader)
        collection.dataSource = self
        collection.delegate = self
        collection.backgroundColor = .clear
        collection.contentInsetAdjustmentBehavior = .always
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPress:)))
        longPressGesture.minimumPressDuration = Constants.longPressDuration
        longPressGesture.delaysTouchesBegan = true
        collection.addGestureRecognizer(longPressGesture)
    }

    /// Handle download.
    ///
    /// - Parameters:
    ///     - medias: list of medias to download
    func handleDownload(_ medias: [GalleryMedia]) {
        guard viewModel?.state.value.downloadStatus != .running else { return }

        loadingMedias = medias
        viewModel?.downloadMedias(loadingMedias, completion: { [weak self] success in
            guard success else { return }

            self?.handleDownloadEnd()
        })
    }

    /// Handle download end.
    func handleDownloadEnd() {
        let medias = loadingMedias.compactMap({ $0.mainMediaItem })
        guard medias.first(where: { $0.isDownloaded == false }) == nil else { return }

        medias.forEach { media in
            if let index = selectedMedias.firstIndex(where: { $0.uid == media.uid }) {
                selectedMedias[index].downloadState = .downloaded
            }
        }

        selectionView.updateButtons(selectedMedias: selectedMedias)
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: { [weak self] in
                                        // Delete loading medias.
                                        guard let medias = self?.loadingMedias else { return }

                                        self?.viewModel?.deleteMedias(medias, completion: { _ in
                                            self?.loadingMedias.removeAll()
                                            self?.viewModel?.refreshMedias()
                                            self?.delegate?.multipleSelectionActionTriggered()
                                        })
                                       })
        let keepAction = AlertAction(title: L10n.commonKeep,
                                     style: .default,
                                     actionHandler: { [weak self] in
                                        // Remove loading files.
                                        self?.loadingMedias.removeAll()
                                        self?.viewModel?.refreshMedias()
                                     })
        let message = loadingMedias.count == 1 ? L10n.galleryDownloadKeep : L10n.galleryDownloadKeepPlural
        showAlert(title: L10n.galleryDownloadComplete,
                  message: message,
                  cancelAction: deleteAction,
                  validateAction: keepAction)
    }

    /// Handle delete.
    ///
    /// - Parameters:
    ///     - medias: list of medias to delete
    func handleDelete(_ medias: [GalleryMedia]) {
        guard viewModel?.state.value.downloadStatus != .running else { return }

        viewModel?.deleteMedias(medias, completion: { [weak self] success in
            guard success else { return }

            self?.viewModel?.refreshMedias()
        })
    }

    /// Handle delete media selection.
    func deleteSelection() {
        let medias = selectedMedias
        delegate?.multipleSelectionActionTriggered()
        handleDelete(medias)
    }

    /// Handle share.
    func handleShare() {
        // TODO: It might be relevant to add a spinner loader instead of the "share" button when medias sharing are loading ?
        var urls: [URL] = []
        let waitingGroup = DispatchGroup()
        let backgroundQueue = DispatchQueue.global(qos: .userInitiated)
        selectedMedias.forEach { selectedMedia in
            selectedMedia.urls?.indices.forEach({ index in
                // Medias loading queue.
                waitingGroup.enter()
                backgroundQueue.async {
                    self.viewModel?.getMediaPreviewImageUrl(selectedMedia, index) { url in
                        if let url = url {
                            urls.append(url)
                        }
                        waitingGroup.leave()
                    }
                }
            })
        }
        waitingGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.coordinator?.showSharingScreen(fromView: strongSelf.view, items: urls)
        }
    }

    /// Handle long press on collection view cell.
    ///
    /// - Parameters:
    ///     - longPress: reference to the gesture recognizer
    @objc func handleLongPress(longPress: UILongPressGestureRecognizer) {
        guard collection.allowsMultipleSelection == false,
              let delegate = delegate,
              let indexPath = collection.indexPathForItem(at: longPress.location(in: collection)) else {
            return
        }

        delegate.multipleSelectionEnabled()
        collectionView(collection, didSelectItemAt: indexPath)
    }
}

// MARK: - CollectionView DataSource
extension GalleryMediaViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].medias.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as GalleryMediaCollectionViewCell
        guard let viewModel = viewModel else { return cell }

        let media = dataSource[indexPath.section].medias[indexPath.row]
        cell.setup(media: media,
                   mediaStore: viewModel.mediaStore,
                   index: viewModel.getMediaImageDefaultIndex(media),
                   delegate: self,
                   selected: selectedMedias.first(where: { $0.uid == media.uid }) != nil)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                       for: indexPath,
                                                                       viewType: GalleryMediaCollectionReusableView.self)
            let date = Array(dataSource)[indexPath.section].key
            cell.setup(date: date)
            return cell
        }

        return UICollectionReusableView()
    }
}

// MARK: - CollectionView Delegate
extension GalleryMediaViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }

        let media = dataSource[indexPath.section].medias[indexPath.row]

        if collectionView.allowsMultipleSelection {
            if let index = selectedMedias.firstIndex(where: { $0.uid == media.uid }) {
                selectedMedias.remove(at: index)
            } else {
                selectedMedias.append(media)
            }

            collectionView.reloadData()
            selectionView.setAllowDownload(viewModel.sourceType != .mobileDevice)
            selectionView.setAllowShare(viewModel.sourceType == .mobileDevice)
            selectionView.setCountAndSizeOfItems(selectedMedias.count, selectedMediasSize)
            selectionView.updateButtons(selectedMedias: selectedMedias)
        } else if let index = viewModel.getMediaIndex(media) {
            self.coordinator?.showMediaPlayer(viewModel: viewModel, index: index)
        }
    }
}

// MARK: - CollectionView FlowLayout Delegate
extension GalleryMediaViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Remove left and right insets
        var collectionViewWidth = collectionView.frame.width - Constants.collectionViewInsets.left - Constants.collectionViewInsets.right
        // Handle safe area screens.
        collectionViewWidth -= UIApplication.shared.windows.first?.safeAreaInsets.left ?? 0.0
        // Compute width.
        let nbColumns = UIApplication.isLandscape ? Constants.nbColumnsLandscape : Constants.nbColumnsPortrait
        let width = collectionViewWidth / nbColumns - Constants.itemSpacing

        // Prevent from issue when rotate.
        guard width >= 0.0 else { return CGSize() }

        return CGSize(width: width, height: width * Constants.cellWidthRatio)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        Constants.collectionViewInsets
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: Constants.headerHeight)
    }
}

// MARK: - GalleryMediaCell Delegate
extension GalleryMediaViewController: GalleryMediaCellDelegate {
    func shouldDownloadMedia(_ media: GalleryMedia) {
        if !collection.allowsMultipleSelection {
            handleDownload([media])
        }
    }
}

// MARK: - Gallery Loading View Delegate.
extension GalleryMediaViewController: GalleryLoadingViewDelegate {
    func shouldStopProgress() {
        viewModel?.cancelDownloads()
    }
}

// MARK: - GalleryView Delegate
extension GalleryMediaViewController: GalleryViewDelegate {
    func stateDidChange(state: GalleryMediaState) {
        self.loadingView.setProgress(state.downloadProgress,
                                     status: state.downloadStatus)
        self.dataSource = state.mediasByDate
        collection.reloadData()
    }

    func multipleSelectionDidChange(enabled: Bool) {
        collection.allowsMultipleSelection = enabled
        selectionView.setAllowDownload(viewModel?.sourceType != .mobileDevice)
        selectionView.setAllowShare(viewModel?.sourceType == .mobileDevice)
        selectionView.setCountAndSizeOfItems(selectedMedias.count, selectedMediasSize)
        selectionView.updateButtons(selectedMedias: selectedMedias)
        selectionView.isHidden = !enabled
        if !collection.allowsMultipleSelection {
            selectedMedias.removeAll()
            collection.reloadData()
        }
    }

    func sourceDidChange(source: GallerySourceType) {
        if collection.allowsMultipleSelection {
            selectionView.setAllowDownload(source != .mobileDevice)
            selectionView.setAllowShare(source == .mobileDevice)
            selectionView.setCountAndSizeOfItems(0, 0)
            selectedMedias.removeAll()
            collection.reloadData()
        }

        viewModel?.setSourceType(type: source)
        viewModel?.setSelectedMediaTypes(types: [])
        viewModel?.refreshMedias()
    }
}

// MARK: - Gallery Selection View Delegate.
extension GalleryMediaViewController: GallerySelectionDelegate {
    func mustDeleteSelection() {
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: { [weak self] in
                                        self?.deleteSelection()
                                       })
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .cancel,
                                       cancelCustomColor: .highlightColor,
                                       actionHandler: {})
        let message: String = viewModel?.sourceType?.deleteConfirmMessage(count: selectedMedias.count) ?? ""
        showAlert(title: L10n.commonDelete,
                  message: message,
                  cancelAction: cancelAction,
                  validateAction: deleteAction)
    }

    func mustDownloadSelection() {
        let medias = selectedMedias
        delegate?.multipleSelectionEnabled()
        handleDownload(medias)
    }

    func mustShareSelection() {
        handleShare()
    }

    func mustSelectAll() {
        selectedMedias = unsortedMedias
        collection.reloadData()
    }

    func mustDeselectAll() {
        selectedMedias.removeAll()
        collection.reloadData()
    }
}
