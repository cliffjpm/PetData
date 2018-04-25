//
//  UIImageCKAsset.swift
//  PetData
//
//  Created by Cliff Anderson on 4/25/18.
//  Copyright © 2018 ArenaK9. All rights reserved.
//

import UIKit
import CloudKit

enum ImageFileType {
    case JPG(compressionQuality: CGFloat)
    case PNG
    
    var fileExtension: String {
        switch self {
        case .JPG(_):
            return ".jpg"
        case .PNG:
            return ".png"
        }
    }
}

enum ImageError: Error {
    typealias RawValue = NSError
    case UnableToConvertImageToData
}

extension CKAsset {
    convenience init(image: UIImage, fileType: ImageFileType = .JPG(compressionQuality: 70)) throws {
        let url = try image.saveToTempLocationWithFileType(fileType: fileType)
        self.init(fileURL: url as URL)
    }
    
    var image: UIImage? {
        guard let data = NSData(contentsOf: fileURL), let image = UIImage(data: data as Data) else { return nil }
        return image
    }
}

extension UIImage {
    func saveToTempLocationWithFileType(fileType: ImageFileType) throws -> URL {
        let imageData: Data?
        
        switch fileType {
        case .JPG(let quality):
            imageData = UIImageJPEGRepresentation(self, quality)
        case .PNG:
            imageData = UIImagePNGRepresentation(self)
        }
        guard let data = imageData else {
            throw ImageError.UnableToConvertImageToData
        }
        
        let filename = ProcessInfo.processInfo.globallyUniqueString + fileType.fileExtension
        let url = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        try data.write(to: url)
        
        return url
    }
}
