//
//  UtilityClasses.swift
//  GLUV-body-scan-native
//
//  Created by Kaustubh Jirapure on 17/10/22.
//

import Foundation

//struct FileNames
//{
//    static let Nrm_Without_Arm: String = "_nrm_WithoutArm"
//    static let Nrm_With_Arm: String = "_nrmPCD"
//    static let Raw_Without_Arm: String = "_std_WithoutArm"
//    static let Raw_With_Arm: String = "_rawPCD"
//    //static let Raw_Non_Processed: String = "_rawData"
//}

enum ApplicationName
{
    case FitXperience
    case FitMatch
    case Macys
    case NativeGluv
}

func GetDocumentDirectoryUrl() -> URL
{
    let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let documentsDirectoryUrl = URL(fileURLWithPath: documentsDirectory)
    return documentsDirectoryUrl
}

func GetLatestScanFolderUrl() -> URL?
{
    let documentsDirectoryUrl = GetDocumentDirectoryUrl()
    let scansFolder = documentsDirectoryUrl.appendingPathComponent("/Scans/")//PointCloudScans/")
    let properties = [URLResourceKey.isDirectoryKey, .localizedNameKey, .creationDateKey, .contentModificationDateKey, .localizedTypeDescriptionKey]
    
    let foldersArray = try? FileManager.default.contentsOfDirectory(at: scansFolder, includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
    let latestDirectory = foldersArray?.sorted(by: {
        return $0.lastPathComponent > $1.lastPathComponent
    })
    
    if latestDirectory?.count ?? 0 < 1 {
        return nil
    }
    
    return latestDirectory![0]
}
