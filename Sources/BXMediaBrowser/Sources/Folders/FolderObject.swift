//----------------------------------------------------------------------------------------------------------------------
//
//  Copyright ©2022 Peter Baumgartner. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//----------------------------------------------------------------------------------------------------------------------


import SwiftUI
import QuickLook


//----------------------------------------------------------------------------------------------------------------------


open class FolderObject : Object
{
	/// Creates a new Object for the file at the specified URL
	
	public init(url:URL)
	{
		super.init(
			identifier: FolderSource.identifier(for:url),
			name: url.lastPathComponent,
			info: url,
			loadThumbnailHandler: Self.loadThumbnail,
			loadMetadataHandler: Self.loadMetadata,
			downloadFileHandler: Self.downloadFile)
	}


	/// Creates a thumbnail image for the specified local file URL
	
	open class func loadThumbnail(for identifier:String, info:Any) async throws -> CGImage
	{
		guard let url = info as? URL else { throw Error.loadThumbnailFailed }
		guard url.exists else { throw Error.loadThumbnailFailed }
		
    	let size = CGSize(width:256, height:256)
        let options = [ kQLThumbnailOptionIconModeKey : kCFBooleanFalse ]
        
        let ref = QLThumbnailImageCreate(
			kCFAllocatorDefault,
			url as CFURL,
			size,
			options as CFDictionary)
        
        guard let thumbnail = ref?.takeUnretainedValue() else { throw Error.loadThumbnailFailed }
		return thumbnail
	}


	/// Loads the metadata dictionary for the specified local file URL
	
	open class func loadMetadata(for identifier:String, info:Any) async throws -> [String:Any]
	{
		guard let url = info as? URL else { throw Error.loadMetadataFailed }
		guard url.exists else { throw Error.loadMetadataFailed }

		var metadata:[String:Any] = [:]
		
		if let fileSize = url.fileSize
		{
			metadata["fileSize"] = fileSize
		}

		if let creationDate = url.creationDate
		{
			metadata["creationDate"] = creationDate
		}

		if let modificationDate = url.modificationDate
		{
			metadata["modificationDate"] = modificationDate
		}
		
		return metadata
	}


	/// Since we are already dealing with a local media file, this function simply returns the specified file URL
	
	open class func downloadFile(for identifier:String, info:Any) async throws -> URL
	{
		guard let url = info as? URL else { throw Error.downloadFileFailed }
		guard url.exists else { throw Error.downloadFileFailed }
		return url
	}
}


//----------------------------------------------------------------------------------------------------------------------


