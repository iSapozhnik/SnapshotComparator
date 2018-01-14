//
//  FileManager.swift
//  SnapshotComparator
//
//  Created by Ivan Sapozhnik on 14.01.18.
//  Copyright © 2018 Ivan Sapozhnik. All rights reserved.
//

import Foundation

struct URLContainer {
    var referenceFolderURL: URL?
    var failedFolderUTL: URL?
}

enum FileType: String {
    case failed = "diff_"
    case reference = "reference_"
}

final class SCFileManager {
    typealias URLCompletion = (URLContainer?, Error?) -> Void
    typealias ImagesCompletion = ([ImageFile]) -> Void
    
    static let shared = SCFileManager()
    private init() {}
    
    private struct Config {
        static let referenceFolderName = "ReferenceImages"
        static let failedTestsFolderName = "FailureDiffs"
    }
    
    let fileManager = FileManager.default
    
    func refresh() {
        
    }
    
    func setupRootsForProjectURL(_ baseURL: URL, completion: @escaping URLCompletion) {
        DispatchQueue.global(qos: .background).async {
            let resourceKeys : [URLResourceKey] = [.nameKey, .isDirectoryKey]
            let enumerator = self.fileManager.enumerator(at: baseURL, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles]) { url, error -> Bool in
                if (error != nil) {
                    print("[Error] %@ (%@)", error, url)
                    return false
                }
                
                return true
            }
            
            guard let unw_enumerator = enumerator else {
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
                return
            }
            do {
                var urlContainer = URLContainer()
                for case let fileURL as URL in unw_enumerator {
                    let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                    if resourceValues.isDirectory!, resourceValues.name! == Config.failedTestsFolderName {
                        print(fileURL.path, resourceValues.isDirectory!)
                        urlContainer.failedFolderUTL = fileURL
                    }
                    if resourceValues.isDirectory!, resourceValues.name! == Config.referenceFolderName {
                        print(fileURL.path, resourceValues.isDirectory!)
                        urlContainer.referenceFolderURL = fileURL
                    }
                }
                DispatchQueue.main.async {
                    completion(urlContainer, nil)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    func loadFilesList(folderURL: URL?, fileType: FileType, completion: @escaping ImagesCompletion) {
        DispatchQueue.global(qos: .background).async {
            var filesList: [URL] = []
            var imageFiles: [ImageFile] = []
            if let selectedFolder = folderURL {
                let folders = self.contentsOf(folder: selectedFolder)
                folders.forEach { url in
                    filesList.append(contentsOf: self.contentsOf(folder: url))
                }
                
                if imageFiles.count > 0 {   // When not initial folder
                    imageFiles.removeAll()
                }
                
                for url in filesList {
                    if url.lastPathComponent.hasPrefix(fileType.rawValue), let imageFile = ImageFile(url: url) {
                        imageFiles.append(imageFile)
                    }
                }
            }
            DispatchQueue.main.async {
                completion(imageFiles)
            }
        }
    }
    
    func contentsOf(folder: URL) -> [URL] {
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
            
            let urls = contents.map { return folder.appendingPathComponent($0) }
            return urls
        } catch {
            return []
        }
    }
}
