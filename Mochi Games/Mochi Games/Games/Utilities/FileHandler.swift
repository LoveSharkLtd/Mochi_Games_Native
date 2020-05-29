//
//  FileHandler.swift
//  Mochi Games
//
//  Created by Sam Weekes on 5/29/20.
//  Copyright © 2020 Sam Weekes. All rights reserved.
//

import Foundation

class FileHandler: NSObject {
    
    static let folderName = "MochiRecordings"
    
    private class func createFolder() {
        
        // path to documents directory
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        
        if let documentDirectoryPath = documentDirectoryPath {
            // create the custom folder path
            let replayDirectoryPath = documentDirectoryPath.appending("/\(FileHandler.folderName)")
            let fileManager = FileManager.default
            
            if !fileManager.fileExists(atPath: replayDirectoryPath) {
                do {
                    try fileManager.createDirectory(atPath: replayDirectoryPath,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
                } catch {
                    print("Error creating Replays folder in documents dir: \(error)")
                }
            }
            else
            {
            }
        }
    }
    
    public class func filePath(_ fileName: String) -> String {
        
        createFolder()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        
        let filePath : String = "\(documentsDirectory)/\(FileHandler.folderName)/\(fileName).mp4"
        
        print("File handler created a path at \(filePath)")
        return filePath
    }
    
    internal class func fetchAllReplays() -> [URL] {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        guard let replayPath = documentsDirectory?.appendingPathComponent("/\(FileHandler.folderName)") else {
            print("file path does not exist")
            return []
        }
        
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: replayPath, includingPropertiesForKeys: nil, options: [])

            return directoryContents
        } catch {
            print(error)
        }
        
        return []
    }
    
}

