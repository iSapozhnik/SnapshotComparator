//
//  ViewController.swift
//  SnapshotComparator
//
//  Created by Ivan Sapozhnik on 05.01.18.
//  Copyright © 2018 Ivan Sapozhnik. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var filesLabel: NSTextField!
    @IBOutlet weak var referenceImagesTableView: NSTableView!
    @IBOutlet weak var actualImageView: NSImageView!
    @IBOutlet weak var referenceImage: NSImageView!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    
    var imageFiles: [ImageFile] = []
    var urlContainer: URLContainer?
    
    var selectedFolder: URL?
    
    var selectedImage: ImageFile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.window?.title = "Snapshot Comparator"
    }
    
    @IBAction func openFolder(_ sender: Any?) {
        guard let window = view.window else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.showsHiddenFiles = false
        
        self.activityIndicator.startAnimation(nil)
        panel.beginSheetModal(for: window) { [weak self] result in
            if result.rawValue == NSFileHandlingPanelOKButton {

                let url = panel.urls[0]
                
                SCFileManager.shared.setupRootsForProjectURL(url, completion: { urlContainer, error in
                    guard let url = urlContainer?.failedFolderUTL else {
                        return
                    }
                    
                    self?.urlContainer = urlContainer
                    self?.selectedFolder = url
                    print(self?.selectedFolder)
                    
                    SCFileManager.shared.loadFilesList(folderURL: url, fileType: .failed, completion: { imageFiles in
                        self?.imageFiles = imageFiles
                        self?.displayFilesCount()
                        self?.activityIndicator.stopAnimation(nil)
                        self?.referenceImagesTableView.reloadData()
                        self?.referenceImagesTableView.scrollRowToVisible(0)
                    })
                })
            } else {
                self?.activityIndicator.stopAnimation(nil)
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        openFolder(nil)
    }
    
    private func displayFilesCount() {
        var coundLabel = "files"
        if imageFiles.count == 1 {
            coundLabel = "file"
        }
        
        filesLabel.stringValue = "(\(imageFiles.count) \(coundLabel))"
    }
}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return imageFiles.count
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    
    func configureCell(_ cell: NSTableCellView, imageFile: ImageFile) {
        cell.textField?.stringValue = imageFile.fileName
        cell.imageView?.image = imageFile.thumbnail
    }
    
    func tableView(_ tableView: NSTableView, viewFor
        tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let imageFile = imageFiles[row]
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileCell"), owner: nil)
            as? NSTableCellView {
            configureCell(cell, imageFile: imageFile)
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileCell"), owner: nil)
            as? NSTableCellView {
            let imageFile = imageFiles[row]
            configureCell(cell, imageFile: imageFile)
            cell.layoutSubtreeIfNeeded()
            return cell.frame.height
        }
        return 0.0
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if referenceImagesTableView.selectedRow < 0 {
            selectedImage = nil
            return
        }

        selectedImage = imageFiles[referenceImagesTableView.selectedRow]
        actualImageView.image = selectedImage?.actualImage
        referenceImage.image = selectedImage?.referenceImage
    }
    
}

